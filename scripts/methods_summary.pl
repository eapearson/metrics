#!/usr/bin/env perl

#
# Reads in a CSV of methods access by day (generated by Splunk)
# and generates summaries
#

use JSON;
use strict;
use Date::Calc qw(Delta_Days);
use POSIX qw/strftime/;

my $json = JSON->new->allow_nonref;

# Get all the users from the log and skip over some bogus splunk columns
#
$_=<STDIN>;
chomp;
my @methods=split /,/;
shift @methods;
my @methodsl;
my $methods;
for my $u (@methods){
  $u=~s/"//g;
  push @methodsl,$u;
  next if $u eq '"-"';
  next if $u eq '-:-';
  next if $u eq 'NULL';
  next if $u =~ '_span';
  next if $u =~ '_spandays';
  $methods->{by_method}->{$u}={};
}

my $start_date=0;
my $end_date=0;
my $time;
my $counts;

# Go through each day and tally up accesses
#
while(<STDIN>){
  chomp;
  my @list=split /,/;
  $time=shift @list;
  $time=~s/T.*//;
  $time=~s/"//;
  my $month=$time;
  $month=~s/...$//; 
  my $i=0;
  $start_date=$time unless $start_date ne 0;
  foreach (@list){
    my $method=$methodsl[$i];
    $i++;
    # Skip if the user isn't in our good list
    #
    #next unless defined $keep{$method};
    next unless defined $methods->{by_method}->{$method};
    next if $_ == 0;
    $method=~s/"//g;
    $methods->{by_method}->{$method}->{accesses_by_month}->{$month}+=$_;
    $methods->{by_method}->{$method}->{total_count}+=$_;
  }
}
$end_date=$time;

my @l=sort {$methods->{by_method}->{$b}->{total_count} <=> $methods->{by_method}->{$a}->{total_count} } keys %{$methods->{by_method}};
push @{$methods->{top_list}},@l[0..20];

my $date=strftime('%Y-%m-%dT%H:%s',gmtime);
$methods->{meta}->{comments}="Generated from a Splunk query and summarized by methods_summary";
$methods->{meta}->{author}="Shane Canon";
$methods->{meta}->{generated}=$date;
$methods->{meta}->{dataset}= "splunk-methods-by-day";
$methods->{meta}->{description} = "Number of methods access by date summarized over each month including grand totals";

print $json->encode($methods);

