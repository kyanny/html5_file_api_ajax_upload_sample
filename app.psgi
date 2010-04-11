# app.psgi
use strict;
use Plack::Request;
use Plack::Response;
use Plack::Builder;
use File::Basename;
use Path::Class;
use JSON;

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

    my $dir = dir('public', 'tmp');
    $dir->mkpath unless -d $dir;

    my $filename = file($dir, time().'.jpg');
    open my $fh, ">", $filename or die $!;
    print $fh $body;
    close $fh or die $!;

    my $json = to_json ["read $size bytes.", "saved as $filename"];

    $res->content_type('application/json');
    $res->body($json);
    return $res;
};

my $indexes_handler = sub {
    my $req = shift;
    my $res = $req->new_response(200);

    my $dir = dir('public', 'tmp');
    my $body;
    while (my $file = $dir->next) {
        next if $file->is_dir;
        $body .= qq{<p><a href="$file">$file</a></p>};
    }

    $res->content_type('text/html');
    $res->body(<<HTML);
<html>
<head>
<title>Index of</title>
</head>
<body>
<pre>
$body
</pre>
</body>
</html>
HTML

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
    elsif ($req->path eq '/indexes') {
        $res = $indexes_handler->($req);
    }

    $res->finalize;
};

builder {
    enable 'Plack::Middleware::Static',
        path => qr/public/, root => dirname(__FILE__);
    $handler;
};
