defmodule AwesomeParser do
  use Application
  def start(_,_), do: Supervisor.start_link([Supervisor.Spec.worker(__MODULE__,[],function: :start_worker)], strategy: :one_for_one)
  def start_worker, do: Exos.Proc.start_link("node .",{},[cd: "#{:code.priv_dir(:awesome_parser)}"],name: __MODULE__)
  def parse(css), do: GenServer.call(__MODULE__,{:parse,css})
end

defmodule FontAwesome do
  def css(version) do
    Mix.shell.info ~s(will download "http://fontawesome.io/assets/font-awesome-#{version}.zip")
    {:ok,{{_,200,_},_,body}} = :httpc.request(:get,{'http://fontawesome.io/assets/font-awesome-#{version}.zip',[]},[],body_format: :binary)
    {:ok,[{_,css}]} = :zip.extract(body,[:memory,file_list: ['font-awesome-#{version}/css/font-awesome.css']])
    File.write!("aw.css",css)
    css
  end
  def icon_decimals(css_ast) do
    for %{type: "rule", selectors: [".fa-"<>_|_]=sels, declarations: [%{property: "content",value: value}]}<-css_ast.stylesheet.rules, ".fa-"<>name <- sels do
      [name,"before"] = String.split(name,":")
      hex_value = value |> String.strip(?") |> String.lstrip(?\\)
      <<value::2*8>> = Base.decode16!(hex_value, case: :lower)
      {name,value}
    end
  end
end

defmodule Mix.Tasks.FontCssToEntities do
  @html """
  <html><head>
    <style>
    body { background-color: 292929; padding: 30px}
    h1 { width: 700px; margin: auto; margin-bottom: 50px; position: relative; color: #c9d0d4; font-family: 'Helvetica Neue', sans-serif; font-size: 46px; font-weight: 100; line-height: 50px; letter-spacing: 1px; padding: 0 0 30px; border-bottom: double #555; }
    table { color: #bbc3c8; font-family: 'Verdana', sans-serif; font-size: 16px; line-height: 26px; margin: auto; }
    .version { color: #bbc3c8; background: #292929; display: inline-block; font-family: 'Georgia', serif; font-style: italic; font-size: 18px; line-height: 22px; margin: 0 0 20px 18px; padding: 10px 12px 8px; position: absolute; bottom: -36px; }
    table,tr { border-collapse: collapse; border: solid 1px #555 }
    td { padding: 10px }
    </style>
    <link href="https://maxcdn.bootstrapcdn.com/font-awesome/<%= version %>/css/font-awesome.min.css" rel="stylesheet" integrity="sha384-wvfXpqpZZVQGK6TAh5PVlGOfQNHSoD2xbE+QkPxCAFlNEevoEH3Sl0sibVcOQVnN" crossorigin="anonymous">
  </head><body>
    <h1>Awesome Font HTML entities <div class="version"><%= version %></div></h1>
    <table>
    <%= for {name, decimal}<- decimals do %>
      <tr><td><i class="fa fa-<%= name %> fa-2x"></i></td><td><%= name %></td><td><strong>&amp;#<%= decimal %>;</strong></td></tr>
    <% end %>
    </table>
  </body></html>
  """
  def run(args) do
    Mix.Task.run "app.start", []
    version = List.first(args) || Mix.Project.config[:default_font_awesome_version]
    fa_decimals = FontAwesome.css(version) |> AwesomeParser.parse |> FontAwesome.icon_decimals
    File.write!("fa_icons.html",EEx.eval_string(@html,decimals: fa_decimals, version: version))
    Mix.shell.info("fa_icons.html created")
  end
end
