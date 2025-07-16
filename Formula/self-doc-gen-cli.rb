class SelfDocGenCli < Formula
  desc "Self-documenting CLI generator with markdown templates and folder visualization"
  homepage "https://github.com/raymonepping/self_doc_gen_cli"
  url "https://github.com/raymonepping/homebrew-self-doc-gen-cli/archive/refs/tags/v1.0.14.tar.gz"
  sha256 "93977b916dc24675162aa40d9f732b0e00784bb31a5b4aa6ad3eb586d6a80238"
  license "MIT"
  version "1.0.14"

  depends_on "bash"

  def install
    bin.install "bin/self_doc" => "self_doc"
    pkgshare.install "tpl" 
    doc.install "README.md"
  end

  def caveats
    <<~EOS
      To get started, run:
        self_doc --help

      To override templates/config:
        export SELF_DOC_HOME=#{opt_pkgshare}

      Template location:
        #{opt_pkgshare}/tpl
    EOS
  end

  test do
    assert_match "Usage", shell_output("#{bin}/self_doc --help")
  end
end
