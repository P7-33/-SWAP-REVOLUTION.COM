# ===========================================================================
#     https://www.gnu.org/software/autoconf-archive/ax_boost_process.html
# ===========================================================================
#
# SYNOPSIS
#
#   AX_BOOST_PROCESS
#
# DESCRIPTION
#
#   Test for Process library from the Boost C++ libraries. The macro
#   requires a preceding call to AX_BOOST_BASE. Further documentation is
#   available at <http://randspringer.de/boost/index.html>.
#
#   This macro calls:
#
#     AC_SUBST(BOOST_PROCESS_LIB)
#
#   And sets:
#
#     HAVE_BOOST_PROCESS
#
# LICENSE
#
#   Copyright (c) 2008 Thomas Porschberg <thomas@randspringer.de>
#   Copyright (c) 2008 Michael Tindal
#   Copyright (c) 2008 Daniel Casimiro <dan.casimiro@gmail.com>
#
#   Copying and distribution of this file, with or without modification, are
#   permitted in any medium without royalty provided the copyright notice
#   and this notice are preserved. This file is offered as-is, without any
#   warranty.

#serial 2

AC_DEFUN
AC_ARG_WITH([boost-process],
	AS_HELP_STRING([--with-boost-process@<:@=special-lib@:>@],
                   [use the Process library from boost - it is possible to specify a certain library for the linker
                        e.g. --with-boost-process=boost_process-gcc-mt ]),
        [
        if test "$withval" = "no"; then
			want_boost_process="no"
        elif test "$withval" = "yes"; then
            want_boost_process="yes"
            ax_boost_user_process_lib=""
        else
		    want_boost_process="yes"
		ax_boost_user_process_lib="$withval"
		fi
        ],
        [want_boost_process="yes"]
	)
	if test "x$want_boost_process" = "xyes"; then
        AC_REQUIRE([AC_PROG_CC])
        AC_REQUIRE([AC_CANONICAL_BUILD])
		CPPFLAGS_SAVED="$CPPFLAGS"
		CPPFLAGS="$CPPFLAGS $BOOST_CPPFLAGS"
		export CPPFLAGS
		LDFLAGS_SAVED="$LDFLAGS"
		LDFLAGS="$LDFLAGS $BOOST_LDFLAGS"
		export LDFLAGS
        AC_CACHE_CHECK(whether the Boost::Process library is available,
					   ax_cv_boost_process,
        [AC_LANG_PUSH([C++])
			 CXXFLAGS_SAVE=$CXXFLAGS
			 CXXFLAGS=
             AC_COMPILE_IFELSE([AC_LANG_PROGRAM([[@%:@include <boost/process.hpp>]],
                [[boost::process::child* child = new boost::process::child; delete child;]])],
                ax_cv_boost_process=yes, ax_cv_boost_process=no)
			 CXXFLAGS=$CXXFLAGS_SAVE
             AC_LANG_POP([C++])
		])
		if test "x$ax_cv_boost_process" = "xyes"; then
			AC_SUBST(BOOST_CPPFLAGS)
			AC_DEFINE(HAVE_BOOST_PROCESS,,[define if the Boost::Process library is available])
            BOOSTLIBDIR=`echo $BOOST_LDFLAGS | sed -e 's/@<:@^\/@:>@*//'`
			LDFLAGS_SAVE=$LDFLAGS
            if test "x$ax_boost_user_process_lib" = "x"; then
                for libextension in `ls -r $BOOSTLIBDIR/libboost_process* 2>/dev/null | sed 's,.*/lib,,' | sed 's,\..*,,'` ; do
                     ax_lib=${libextension}
				    AC_CHECK_LIB($ax_lib, exit,
                                 [BOOST_PROCESS_LIB="-l$ax_lib"; AC_SUBST(BOOST_PROCESS_LIB) link_process="yes"; break],
                                 [link_process="no"])
				done
                if test "x$link_process" != "xyes"; then
                for libextension in `ls -r $BOOSTLIBDIR/boost_process* 2>/dev/null | sed 's,.*/,,' | sed -e 's,\..*,,'` ; do
                     ax_lib=${libextension}
				    AC_CHECK_LIB($ax_lib, exit,
                                 [BOOST_PROCESS_LIB="-l$ax_lib"; AC_SUBST(BOOST_PROCESS_LIB) link_process="yes"; break],
                                 [link_process="no"])
				done
                fi
            else
               for ax_lib in $ax_boost_user_process_lib boost_process-$ax_boost_user_process_lib; do
				      AC_CHECK_LIB($ax_lib, exit,
                                   [BOOST_PROCESS_LIB="-l$ax_lib"; AC_SUBST(BOOST_PROCESS_LIB) link_process="yes"; break],
                                   [link_process="no"])
                  done
            fi
            if test "x$ax_lib" = "x"; then
                AC_MSG_ERROR(Could not find a version of the Boost::Process library!)
            fi
			if test "x$link_process" = "xno"; then
				AC_MSG_ERROR(Could not link against $ax_lib !)
			fi
		fi
		
		CPPFLAGS="$CPPFLAGS_SAVED"
	LDFLAGS="$LDFLAGS_SAVED"
fi
])
version: '{branch}.{build}'
skip_tags: true
image: Visual Studio 2019
configuration: Release
platform: x64
clone_depth: 5
environment:
  PATH: 'C:\Python37-x64;C:\Python37-x64\Scripts;%PATH%'
  PYTHONUTF8: 1
  QT_DOWNLOAD_URL: 'https://github.com/sipsorcery/qt_win_binary/releases/download/qt598x64_vs2019_v1681/qt598_x64_vs2019_1681.zip'
  QT_DOWNLOAD_HASH: '00cf7327818c07d74e0b1a4464ffe987c2728b00d49d4bf333065892af0515c3'
  QT_LOCAL_PATH: 'C:\Qt5.9.8_x64_static_vs2019'
  VCPKG_TAG: '2020.11-1'
install:
# Disable zmq test for now since python zmq library on Windows would cause Access violation sometimes.
# - cmd: pip install zmq
# The powershell block below is to set up vcpkg to install the c++ dependencies. The pseudo code is:
#    a. Checkout the vcpkg source (including port files) for the specific checkout and build the vcpkg binary,
#    b. Append a setting to the vcpkg cmake config file to only do release builds of dependencies (skipping deubg builds saves ~5 mins).
# Note originally this block also installed the dependencies using 'vcpkg install'. Dependencies are now installed
# as part of the msbuild command using vcpkg mainfests.
- ps: |
      cd c:\tools\vcpkg
      $env:GIT_REDIRECT_STDERR = '2>&1' # git is writing non-errors to STDERR when doing git pull. Send to STDOUT instead.
      git -c advice.detachedHead=false checkout $env:VCPKG_TAG
      .\bootstrap-vcpkg.bat > $null
      Add-Content "C:\tools\vcpkg\triplets\$env:PLATFORM-windows-static.cmake" "set(VCPKG_BUILD_TYPE release)"
      cd "$env:APPVEYOR_BUILD_FOLDER"
before_build:
# Powershell block below is to download and extract the Qt static libraries. The pseudo code is:
#    a. Download the zip file with the prebuilt Qt static libraries.
#    b. Check that the downloaded file matches the expected hash.
#    c. Extract the zip file to the specific destination path expected by the msbuild projects.
- ps: |
      Write-Host "Downloading Qt binaries.";
      Invoke-WebRequest -Uri $env:QT_DOWNLOAD_URL -Out qtdownload.zip;
      Write-Host "Qt binaries successfully downloaded, checking hash against $env:QT_DOWNLOAD_HASH...";
      if((Get-FileHash qtdownload.zip).Hash -eq $env:QT_DOWNLOAD_HASH) {
        Expand-Archive qtdownload.zip -DestinationPath $env:QT_LOCAL_PATH;
        Write-Host "Qt binary download matched the expected hash.";
      }
      else {
        Write-Host "ERROR: Qt binary download did not match the expected hash.";
        Exit-AppveyorBuild;
      }
- cmd: python build_msvc\msvc-autogen.py
build_script:
- cmd: msbuild /p:TrackFileAccess=false build_msvc\.sln /m /v:q /nologo
after_build:
#- 7z a bitcoin-%APPVEYOR_BUILD_VERSION%.zip %APPVEYOR_BUILD_FOLDER%\build_msvc\%platform%\%configuration%\*.exe
test_script:
- cmd: src\test_Browser Coin Company.Com.exe -l test_suite
- cmd: src\bench_Browser Coin Company.Com.exe > NUL
- ps:  python test\util\Browser Coin Company.Com-util-test.py
- cmd: python test\util\rpcauth-test.py
# Fee estimation test failing on appveyor with: WinError 10048] Only one usage of each socket address (protocol/network address/port) is normally permitted.
# functional tests disabled for now. See
# https://github.com/bitcoin/bitcoin/pull/18626#issuecomment-613396202
# https://github.com/bitcoin/bitcoin/issues/18623
# - cmd: python test\functional\test_runner.py --ci --quiet --combinedlogslen=4000 --failfast --exclude feature_fee_estimation
artifacts:
#- path: bitcoin-%APPVEYOR_BUILD_VERSION%.zip
