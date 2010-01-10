#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Exception;
use Test::Moose;
use Test::Path::Router;
use Plack::Test;

BEGIN {
    use_ok('OX::Application');
}

use lib 't/apps/Counter-Over-Engineered/lib';

use Counter::Over::Engineered;

my $app = Counter::Over::Engineered->new;
isa_ok($app, 'Counter::Over::Engineered');
isa_ok($app, 'OX::Application');

#diag $app->_dump_bread_board;

my $root = $app->fetch_service('app_root');
isa_ok($root, 'Path::Class::Dir');
is($root, 't/apps/Counter-Over-Engineered', '... got the right root dir');

my $template_root = $app->fetch_service('template_root');
isa_ok($template_root, 'Path::Class::Dir');
is($template_root, 't/apps/Counter-Over-Engineered/root/templates', '... got the right template_root dir');

my $router = $app->fetch_service('Router');
isa_ok($router, 'Path::Router');

path_ok($router, $_, '... ' . $_ . ' is a valid path')
for qw[
    /
    /inc
    /dec
    /reset
];

routes_ok($router, {
    ''      => { controller => 'root', action => 'index' },
    'inc'   => { controller => 'root', action => 'inc'   },
    'dec'   => { controller => 'root', action => 'dec'   },
    'reset' => { controller => 'root', action => 'reset' },
},
"... our routes are valid");

my $title = qr/<title>OX - Counter::Over::Engineered Example<\/title>/;

test_psgi
      app    => $app->to_app,
      client => sub {
          my $cb = shift;
          {
              my $req = HTTP::Request->new(GET => "http://localhost");
              my $res = $cb->($req);
              like($res->content, $title, '... got the right title');
              like($res->content, qr/<h1>0<\/h1>/, '... got the right content in index');
          }
          {
              my $req = HTTP::Request->new(GET => "http://localhost/inc");
              my $res = $cb->($req);
              like($res->content, $title, '... got the right title');
              like($res->content, qr/<h1>1<\/h1>/, '... got the right content in /inc');
          }
          {
              my $req = HTTP::Request->new(GET => "http://localhost/inc");
              my $res = $cb->($req);
              like($res->content, $title, '... got the right title');
              like($res->content, qr/<h1>2<\/h1>/, '... got the right content in /inc');
          }
          {
              my $req = HTTP::Request->new(GET => "http://localhost/dec");
              my $res = $cb->($req);
              like($res->content, $title, '... got the right title');
              like($res->content, qr/<h1>1<\/h1>/, '... got the right content in /dec');
          }
          {
              my $req = HTTP::Request->new(GET => "http://localhost/reset");
              my $res = $cb->($req);
              like($res->content, $title, '... got the right title');
              like($res->content, qr/<h1>0<\/h1>/, '... got the right content in /reset');
          }
          {
              my $req = HTTP::Request->new(GET => "http://localhost");
              my $res = $cb->($req);
              like($res->content, $title, '... got the right title');
              like($res->content, qr/<h1>0<\/h1>/, '... got the right content in index');
          }
      };

done_testing;