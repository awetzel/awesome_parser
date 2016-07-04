defmodule Mix.Tasks.Compile.Npm do
  def run([]) do
    if File.exists?("priv/node_modules") do
      Mix.shell.info(~s(priv/node_modules already exists, do not "npm install", do it manually to update libs))
    else
      System.cmd "npm", ["install"], cd: "priv", into: IO.stream(:stdio,:line)
    end
  end
end

defmodule AwesomeParser.Mixfile do
  use Mix.Project

  def project do
    [app: :awesome_parser,
     version: "0.0.1",
     elixir: "~> 1.2",
     compilers: Mix.compilers ++ [:npm],
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     deps: deps,
     ## Change this configuration if you want another default version
     default_font_awesome_version: "4.6.3"]
  end

  def application do
    [applications: [:logger,:inets],mod: {AwesomeParser,[]}]
  end

  defp deps do
    [{:exos,"1.0.0"}]
  end
end
