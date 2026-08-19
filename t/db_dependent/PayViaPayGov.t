#!/usr/bin/perl

# This file is part of Koha.
#
# Koha is free software; you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 3 of the License, or
# (at your option) any later version.
#
# Koha is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with Koha; if not, see <http://www.gnu.org/licenses>.

use Modern::Perl;

use Test::More tests => 9;
use Test::Exception;

use Koha::Database;
use Koha::Encryption;

use t::lib::Mocks;

use Koha::Plugin::Com::ByWaterSolutions::PayViaPayGov;

my $schema = Koha::Database->new->schema;

my $PREFIX = $Koha::Plugin::Com::ByWaterSolutions::PayViaPayGov::ENCRYPTION_PREFIX;

t::lib::Mocks::mock_config( 'encryption_key', 'a test encryption passphrase' );

my $plugin = Koha::Plugin::Com::ByWaterSolutions::PayViaPayGov->new( { enable_plugins => 1 } );

# Every subtest calls upgrade() directly. It can't be triggered the normal way here because
# $VERSION is the literal string '{VERSION}' until the kpz is built, so Koha's version
# comparison in Koha::Plugins::Base always decides this is a downgrade and skips the hook.

subtest 'upgrade() migrates a cleartext credential' => sub {
    plan tests => 5;
    $schema->storage->txn_begin;

    $plugin->store_data( { PayGovApiPassword => 'cleartext-password' } );
    unlike( $plugin->retrieve_data('PayGovApiPassword'), qr/^\Q$PREFIX\E/, 'stored value starts out unencrypted' );

    is( $plugin->upgrade, 1, 'upgrade() returns 1' );

    my $stored = $plugin->retrieve_data('PayGovApiPassword');
    like( $stored, qr/^\Q$PREFIX\E/, 'stored value now carries the encryption prefix' );
    isnt( $stored, 'cleartext-password', 'stored value is no longer the cleartext credential' );
    is( $plugin->_get_secret('PayGovApiPassword'), 'cleartext-password', 'the original credential is recoverable' );

    $schema->storage->txn_rollback;
};

subtest 'upgrade() is idempotent' => sub {
    plan tests => 3;
    $schema->storage->txn_begin;

    $plugin->store_data( { PayGovApiPassword => 'cleartext-password' } );
    $plugin->upgrade;
    my $after_first = $plugin->retrieve_data('PayGovApiPassword');

    is( $plugin->upgrade, 1, 'a second upgrade() returns 1' );
    is( $plugin->retrieve_data('PayGovApiPassword'), $after_first, 'the stored value is byte-identical, so it was not re-encrypted' );
    is( $plugin->_get_secret('PayGovApiPassword'), 'cleartext-password', 'the credential still decrypts to the original' );

    $schema->storage->txn_rollback;
};

subtest 'upgrade() handles an empty or absent credential' => sub {
    plan tests => 4;
    $schema->storage->txn_begin;

    $plugin->store_data( { PayGovApiPassword => undef } );
    is( $plugin->upgrade, 1, 'upgrade() returns 1 with no credential stored' );
    is( $plugin->retrieve_data('PayGovApiPassword'), undef, 'nothing was written' );

    $plugin->store_data( { PayGovApiPassword => q{} } );
    is( $plugin->upgrade, 1, 'upgrade() returns 1 with an empty credential' );
    is( $plugin->retrieve_data('PayGovApiPassword'), q{}, 'the empty value was left as-is, not encrypted' );

    $schema->storage->txn_rollback;
};

subtest 'upgrade() is a no-op without an encryption key' => sub {
    plan tests => 3;
    $schema->storage->txn_begin;

    t::lib::Mocks::mock_config( 'encryption_key', q{} );

    $plugin->store_data( { PayGovApiPassword => 'cleartext-password' } );

    my $returned;
    lives_ok { $returned = $plugin->upgrade } 'upgrade() does not die, so the plugin cannot vanish from the plugin list';
    is( $returned, 1, 'upgrade() still returns 1, so Koha will not retry it forever' );
    is( $plugin->retrieve_data('PayGovApiPassword'), 'cleartext-password', 'the credential is left in cleartext and still usable' );

    t::lib::Mocks::mock_config( 'encryption_key', 'a test encryption passphrase' );

    $schema->storage->txn_rollback;
};

subtest 'migration runs later once an encryption key is configured' => sub {
    plan tests => 3;
    $schema->storage->txn_begin;

    t::lib::Mocks::mock_config( 'encryption_key', q{} );
    $plugin->store_data( { PayGovApiPassword => 'cleartext-password' } );
    $plugin->upgrade;
    is( $plugin->retrieve_data('PayGovApiPassword'), 'cleartext-password', 'still cleartext while no key is set' );

    # The one-shot upgrade() hook will never fire again, so opening the configuration page
    # has to be able to finish the migration
    t::lib::Mocks::mock_config( 'encryption_key', 'a test encryption passphrase' );
    $plugin->_encrypt_stored_credentials;

    like( $plugin->retrieve_data('PayGovApiPassword'), qr/^\Q$PREFIX\E/, 'encrypted once a key is available' );
    is( $plugin->_get_secret('PayGovApiPassword'), 'cleartext-password', 'the credential is unchanged' );

    $schema->storage->txn_rollback;
};

subtest '_set_secret() and _get_secret() round-trip' => sub {
    plan tests => 3;
    $schema->storage->txn_begin;

    $plugin->_set_secret( 'PayGovApiPassword', 'a-brand-new-password' );

    my $stored = $plugin->retrieve_data('PayGovApiPassword');
    like( $stored, qr/^\Q$PREFIX\E/, 'the value was stored with the encryption prefix' );
    unlike( $stored, qr/a-brand-new-password/, 'the cleartext credential does not appear in the stored value' );
    is( $plugin->_get_secret('PayGovApiPassword'), 'a-brand-new-password', 'the credential round-trips' );

    $schema->storage->txn_rollback;
};

subtest '_get_secret() passes through unencrypted values' => sub {
    plan tests => 2;
    $schema->storage->txn_begin;

    $plugin->store_data( { PayGovApiPassword => 'legacy-cleartext' } );
    is( $plugin->_get_secret('PayGovApiPassword'), 'legacy-cleartext', 'an unprefixed value is returned as-is' );

    $plugin->store_data( { PayGovApiPassword => undef } );
    is( $plugin->_get_secret('PayGovApiPassword'), undef, 'a missing credential returns undef rather than dying' );

    $schema->storage->txn_rollback;
};

subtest '_get_secret() fails closed' => sub {
    plan tests => 2;
    $schema->storage->txn_begin;

    $plugin->store_data( { PayGovApiPassword => $PREFIX . 'deadbeefdeadbeef' } );
    throws_ok { $plugin->_get_secret('PayGovApiPassword') } qr/unable to decrypt/,
        'a corrupted credential dies instead of being sent to PayGov';

    $plugin->_set_secret( 'PayGovApiPassword', 'a-brand-new-password' );
    t::lib::Mocks::mock_config( 'encryption_key', q{} );
    throws_ok { $plugin->_get_secret('PayGovApiPassword') } qr/encryption is unavailable/,
        'an encrypted credential dies when the key is gone';
    t::lib::Mocks::mock_config( 'encryption_key', 'a test encryption passphrase' );

    $schema->storage->txn_rollback;
};

subtest 'a blank credential does not overwrite the stored one' => sub {
    plan tests => 3;
    $schema->storage->txn_begin;

    $plugin->_set_secret( 'PayGovApiPassword', 'the-real-password' );
    my $stored = $plugin->retrieve_data('PayGovApiPassword');

    $plugin->_set_secret( 'PayGovApiPassword', q{} );
    is( $plugin->retrieve_data('PayGovApiPassword'), $stored, 'an empty submitted value leaves the stored credential alone' );

    $plugin->_set_secret( 'PayGovApiPassword', undef );
    is( $plugin->retrieve_data('PayGovApiPassword'), $stored, 'an absent submitted value leaves the stored credential alone' );

    my $template = $plugin->mbf_read('configure.tt');
    unlike( $template, qr/name="PayGovApiPassword"[^>]*value="\[%\s*PayGovApiPassword/,
        'configure.tt never renders the stored credential back into the form field' );

    $schema->storage->txn_rollback;
};
