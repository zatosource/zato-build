# Documentation: https://docs.brew.sh/Formula-Cookbook
#                https://rubydoc.brew.sh/Formula
# PLEASE REMOVE ALL GENERATED COMMENTS BEFORE SUBMITTING YOUR PULL REQUEST!
class Zato < Formula
  include Language::Python::Virtualenv

  desc "The next generation ESB and application server. Open-source. In Python"
  homepage "http://zato.io"
  # url "https://github.com/zatosource/zato.git"
  head "https://github.com/zatosource/zato.git", :branch => "main"
                                         #, :revision => "090930930295adslfknsdfsdaffnasd13"
                                         # or :branch => "develop" (the default is "master")
                                         # or :tag => "1_0_release",
                                         #    :revision => "090930930295adslfknsdfsdaffnasd13"

  version "3.2.0"
  # sha256 ""
  # license ""

  depends_on "python@3.8"
  depends_on "pyenv-virtualenvwrapper"
  depends_on "llvm"
  depends_on "autoconf"
  depends_on "automake"
  depends_on "bzip2"
  depends_on "curl"
  depends_on "git"
  depends_on "gsasl"
  depends_on "haproxy"
  depends_on "libev"
  depends_on "libevent"
  depends_on "libffi"
  depends_on "libtool"
  depends_on "libxml2"
  depends_on "libxslt"
  depends_on "libyaml"
  depends_on "openldap"
  depends_on "openssl"
  depends_on "ossp-uuid"
  depends_on "pkg-config"
  depends_on "postgresql"
  depends_on "swig"

  resource "importlib-metadata" do
    url "https://files.pythonhosted.org/packages/56/1f/74c3e29389d34feea2d62ba3de1169efea2566eb22e9546d379756860525/importlib_metadata-2.0.0.tar.gz"
    sha256 "77a540690e24b0305878c37ffd421785a6f7e53c8b5720d211b211de8d0e95da"
  end

  def install
    python = Formula["python@3.8"].opt_bin/"python3"
    ENV["PYTHON"] = python
    # virtualenv_install_with_resources
    # Create a virtualenv in `libexec`. If your app needs Python 3, make sure that
    # `depends_on "python"` is declared, and use `virtualenv_create(libexec, "python3")`.
    venv = virtualenv_create(libexec, python)
    # Install all of the resources declared on the formula into the virtualenv.
    venv.pip_install resources

    cd "code" do
      # system Formula["python@3.x"].opt_bin/"python3", *Language::Python.setup_install_args(prefix)
      system "./install.sh"
    end
    # ENV.deparallelize  # if your formula fails when building in parallel
    # Remove unrecognized options if warned by configure
    # system "cd code"
    # "./configure", "--disable-debug",
    #                       "--disable-dependency-tracking",
    #                       "--disable-silent-rules",
    #                       "--prefix=#{prefix}"
    # system "cmake", ".", *std_cmake_args

    # `pip_install_and_link` takes a look at the virtualenv's bin directory
    # before and after installing its argument. New scripts will be symlinked
    # into `bin`. `pip_install_and_link buildpath` will install the package
    # that the formula points to, because buildpath is the location where the
    # formula's tarball was unpacked.
    venv.pip_install_and_link buildpath
  end

  #test do
    # `test do` will create, run in and delete a temporary directory.
    #
    # This test will fail and we won't accept that! For Homebrew/homebrew-core
    # this will need to be a test that verifies the functionality of the
    # software. Run the test with `brew test zato`. Options passed
    # to `brew install` such as `--HEAD` also need to be provided to `brew test`.
    #
    # The installed folder is not in the path, so use the entire path to any
    # executables being tested: `system "#{bin}/program", "do", "something"`.
  #  system "false"
  #end
end
