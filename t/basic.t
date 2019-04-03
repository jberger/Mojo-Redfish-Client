use Mojo::Base -strict;

use Mojolicious;
use Mojo::Redfish::Client;

use Test::More;

my $mock = Mojolicious->new;
my ($user, $pass, $token);
{
  my $r = $mock->routes;
  $r = $r->under(sub{
    my $c = shift;
    my $url = $c->req->url->to_abs;
    $user   = $url->username;
    $pass   = $url->password;
    $token  = $c->req->headers->header('X-Auth-Token');
    return 1;
  });
  $r->get('/redfish/v1' => {json => {
    '@odata.id' => '/redfish/v1',
    Systems => { '@odata.id' => '/redfish/v1/Systems' }
  }});
  $r->get('/redfish/v1/Systems' => {json => {
    '@odata.id' => '/redfish/v1/Systems',
    Members => [
      {'@odata.id' => '/redfish/v1/Systems/0'},
      {'@odata.id' => '/redfish/v1/Systems/1'},
    ]
  }});
}

my $client = Mojo::Redfish::Client->new(
  ssl => undef,
  username => 'myuser',
  password => 'mypass',
);
$client->ua->server->app($mock);

my $root = $client->root;
is $user, 'myuser', 'got expected username';
is $pass, 'mypass', 'got expected password';
ok !$token, 'no token';
is $root->value('/@odata.id'), '/redfish/v1', 'got expected result';
is $root->value('/Systems/@odata.id'), '/redfish/v1/Systems', 'got expected result';

done_testing;

