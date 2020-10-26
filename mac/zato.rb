# Documentation: https://docs.brew.sh/Formula-Cookbook
#                https://rubydoc.brew.sh/Formula
# PLEASE REMOVE ALL GENERATED COMMENTS BEFORE SUBMITTING YOUR PULL REQUEST!
class Zato < Formula
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

  # depends_on "cmake" => :build

  depends_on "pkg-config"
  depends_on "jpeg"
  depends_on "git"
  depends_on "haproxy"
  depends_on "pyenv-virtualenvwrapper"

  # depends_on ""
  depends_on :xcode => "9.3"  

  def install
    # Create a virtualenv in `libexec`. If your app needs Python 3, make sure that
    # `depends_on "python"` is declared, and use `virtualenv_create(libexec, "python3")`.
    venv = virtualenv_create(libexec)
    # Install all of the resources declared on the formula into the virtualenv.
    venv.pip_install resources
    # `pip_install_and_link` takes a look at the virtualenv's bin directory
    # before and after installing its argument. New scripts will be symlinked
    # into `bin`. `pip_install_and_link buildpath` will install the package
    # that the formula points to, because buildpath is the location where the
    # formula's tarball was unpacked.
    venv.pip_install_and_link buildpath
    
    # ENV.deparallelize  # if your formula fails when building in parallel
    # Remove unrecognized options if warned by configure
    system "cd code"
    system "./install.sh"
    # "./configure", "--disable-debug",
    #                       "--disable-dependency-tracking",
    #                       "--disable-silent-rules",
    #                       "--prefix=#{prefix}"
    # system "cmake", ".", *std_cmake_args
  end

  test do
    # `test do` will create, run in and delete a temporary directory.
    #
    # This test will fail and we won't accept that! For Homebrew/homebrew-core
    # this will need to be a test that verifies the functionality of the
    # software. Run the test with `brew test zato`. Options passed
    # to `brew install` such as `--HEAD` also need to be provided to `brew test`.
    #
    # The installed folder is not in the path, so use the entire path to any
    # executables being tested: `system "#{bin}/program", "do", "something"`.
    system "false"
  end
end
