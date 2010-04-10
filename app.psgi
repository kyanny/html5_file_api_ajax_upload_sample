# app.psgi
use strict;
use Plack::Request;
use Plack::Response;
use Plack::Builder;
use File::Basename;
use File::Path;
use File::Spec;
use JSON;
use Digest::SHA1 qw(sha1_hex);

my $root_handler = sub {
    my $req = shift;
    my $res = $req->new_response(200);

    $res->content_type('text/html');
    $res->body(<<HTML);
<html>
<body>
goto <a href="public/index.html">demo</a>
</body>
</html>
HTML

    return $res;
};

my $upload_handler = sub {
    my $req = shift;
    my $res = $req->new_response(200);

    my $body;
    my $buf;
    while ($req->input->read($buf, 1024)) {
        $body .= $buf;
    }
    my $size = length $body;

    my $tmp = mkpath('public/tmp');
    my $tmp = File::Spec->catdir('public', 'tmp');
    mkpath($tmp) unless -d $tmp;

    my $filename = File::Spec->catdir($tmp, sha1_hex($body).'.jpg');
    open my $fh, ">", $filename or die $!;
    print $fh $body;
    close $fh or die $!;

    my $json = to_json ["read $size bytes.", "saved as $filename"];

    $res->content_type('application/json');
    $res->body($json);
    return $res;
};

my $handler = sub {
    my $env = shift;
    my $req = Plack::Request->new($env);
    my $res;

    if ($req->path eq '/') {
        $res = $root_handler->($req);
    }
    elsif ($req->path eq '/upload') {
        $res = $upload_handler->($req);
    }

    $res->finalize;
};

builder {
    enable 'Plack::Middleware::Static',
        path => qr/public/, root => dirname(__FILE__);
    $handler;
};
