#!/bin/perl -w

$verbose = 1;
my $diffexists = `which diff`;
if ($diffexists eq "") { die "diff not found in path.\n"; }

my $script  = "COLUMNS=78 ./pandoc";

use Getopt::Long;
GetOptions("script=s" => \$script);

unless (-f $script)   { die "$script does not exist.\n"; }
unless (-x $script)   { die "$script is not executable.\n"; }

print "Writer tests:\n";

my @writeformats = ("html", "latex", "rst", "rtf", "markdown", "man", "native"); # docbook, context, and s5 handled separately
my $source = "testsuite.native";

sub test_results 
{
    my $testname = $_[0];
    my $output = $_[1];
    my $norm = $_[2];
    my $diffoutput = `diff --strip-trailing-cr $output $norm`;
    if ($diffoutput eq "") 
    {
        print "passed\n";
    }
    else
    {
        print "FAILED\n";
        if ($verbose) { print $diffoutput;  } 
    } 
}

foreach my $format (@writeformats)
{
    $options = "";

    my $extension = $format;
    print "Testing $format writer...";

    `$script -r native -w $extension $options -s $source > tmp.$extension`;

    test_results("$format writer", "tmp.$extension", "writer.$format");

    print "        $format tables...";

    `$script -r native -w $extension tables.native > tmp.$extension`;

    test_results("$format writer", "tmp.$extension", "tables.$format");
}

print "Testing docbook writer...";
# remove HTML block tests, as this produces invalid docbook...
`sed -e '/^, Header 1 \\[Str "HTML",Space,Str "Blocks"\\]/,/^, HorizontalRule/d' testsuite.native | $script -r native -w docbook -s > tmp.docbook`;
test_results("docbook writer", "tmp.docbook", "writer.docbook");
`$script -r native -w docbook tables.native > tmp.docbook`;
print "        docbook tables...";
test_results("docbook tables", "tmp.docbook", "tables.docbook");

print "Testing context writer...";
# remove LaTeX tests, as this produces invalid docbook...
`sed -e '/^, Header 1 \\[Str "LaTeX"\\]/,/^, HorizontalRule/d' testsuite.native | $script -r native -w context -s > tmp.context`;
test_results("context writer", "tmp.context", "writer.context");
`$script -r native -w context tables.native > tmp.context`;
print "        context tables...";
test_results("context tables", "tmp.context", "tables.context");

print "Testing s5 writer (basic)...";
`$script -r native -w s5 -s s5.native > tmp.html`;
test_results("s5 writer (basic)", "tmp.html", "s5.basic.html");

print "Testing s5 writer (fancy)...";
`$script -r native -w s5 -s -m -i s5.native > tmp.html`;
test_results("s5 writer (fancy)", "tmp.html", "s5.fancy.html");

print "Testing html fragment...";
`$script -r native -w html s5.native > tmp.html`;
test_results("html fragment", "tmp.html", "s5.fragment.html");

print "Testing -H -B -A -c options...";
`$script -r native -s -w html -H insert -B insert -A insert -c main.css s5.native > tmp.html`;
test_results("-B, -A, -H, -c options", "tmp.html", "s5.inserts.html");

print "\nReader tests:\n";

print "Testing markdown reader...";
`$script -r markdown -w native -s -S testsuite.txt > tmp.native`;
test_results("markdown reader", "tmp.native", "testsuite.native");

print "Testing rst reader...";
`$script -r rst -w native -s rst-reader.rst > tmp.native`;
test_results("rst reader", "tmp.native", "rst-reader.native");

print "Testing html reader...";
`$script -r html -w native -s html-reader.html > tmp.native`;
test_results("html reader", "tmp.native", "html-reader.native");

print "Testing latex reader...";
`$script -r latex -w native -s latex-reader.latex > tmp.native`;
test_results("latex reader", "tmp.native", "latex-reader.native");

print "Testing native reader...";
`$script -r native -w native -s testsuite.native > tmp.native`;
test_results("native reader", "tmp.native", "testsuite.native");

`rm tmp.*`;

