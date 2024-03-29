
# This file was automatically generated by Dist::Zilla::Plugin::MakeMaker v5.019.
use strict;
use warnings;



use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "Packing Algorithm",
  "AUTHOR" => "JT Smith <jt\@plainblack.com>",
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "Box-Calc",
  "EXE_FILES" => [],
  "LICENSE" => "perl",
  "NAME" => "Box::Calc",
  "PREREQ_PM" => {
    "AnyEvent" => 0,
    "AnyEvent::HTTP::LWP::UserAgent" => 0,
    "Data::GUID" => 0,
    "JSON" => "2.0",
    "Log::Any" => 0,
    "Moose" => 0,
    "Ouch" => "0.0400",
    "Test::Deep" => 0,
    "Test::More" => 0
  },
  "VERSION" => "1.0001",
  "test" => {
    "TESTS" => "t/*.t"
  }
);


my %FallbackPrereqs = (
  "AnyEvent" => 0,
  "AnyEvent::HTTP::LWP::UserAgent" => 0,
  "Data::GUID" => 0,
  "JSON" => "2.0",
  "Log::Any" => 0,
  "Moose" => 0,
  "Ouch" => "0.0400",
  "Test::Deep" => 0,
  "Test::More" => 0
);


unless ( eval { ExtUtils::MakeMaker->VERSION(6.63_03) } ) {
  delete $WriteMakefileArgs{TEST_REQUIRES};
  delete $WriteMakefileArgs{BUILD_REQUIRES};
  $WriteMakefileArgs{PREREQ_PM} = \%FallbackPrereqs;
}

delete $WriteMakefileArgs{CONFIGURE_REQUIRES}
  unless eval { ExtUtils::MakeMaker->VERSION(6.52) };

WriteMakefile(%WriteMakefileArgs);



