defmodule AwesomeParser do
  use Application
  def start(_,_), do: Supervisor.start_link([Supervisor.Spec.worker(__MODULE__,[],function: :start_worker)], strategy: :one_for_one)
  def start_worker, do: Exos.Proc.start_link("node .",{},[cd: "#{:code.priv_dir(:awesome_parser)}"],name: __MODULE__)
  def parse(css), do: GenServer.call(__MODULE__,{:parse,css})
end

defmodule Mix.Tasks.FontCssToEntities do
  def run(args) do
    Mix.Task.run "app.start", []
    version = List.first(args) || Mix.Project.config[:default_font_awesome_version]
    url = "http://fontawesome.io/assets/font-awesome-#{version}.zip"
    {:ok,{{_,200,_},_,body}} = :httpc.request(:get,{'#{url}',[]},[],body_format: :binary)
    {:ok,[{_,css}]} = :zip.extract(body,[:memory,file_list: ['font-awesome-#{version}/css/font-awesome.css']])
    css_ast = AwesomeParser.parse(css)
    for %{type: "rule", selectors: [".fa-"<>name], declarations: [%{property: "content",value: value}]}<-css_ast.stylesheet.rules do
      [name,"before"] = String.split(name,":")
      hex_value = value |> String.strip(?") |> String.lstrip(?\\)
      <<value::2*8>> = Base.decode16!(hex_value, case: :lower)
      IO.puts "name: #{name}, entity: &##{value};"
    end
  end
end
