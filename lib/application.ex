defmodule ExARIExample.Application do
  @moduledoc """
  Documentation for ExAriExample.
  """
  use Application
  alias ARI.{ChannelRegistrar, Configurator, HTTP, Stasis}
  alias ExARIExample.Router

  def start(_, _) do
    un = System.get_env("ASTERISK_USERNAME")
    pw = System.get_env("ASTERISK_PASSWORD")
    ws_host = System.get_env("ASTERISK_WS_HOST")
    rest_host = System.get_env("ASTERISK_REST_HOST")
    rest_port = System.get_env("ASTERISK_REST_PORT") |> String.to_integer()
    name = System.get_env("ASTERISK_NAME")
    transport = System.get_env("ASTERISK_TRANSPORT")
    context = System.get_env("ASTERISK_CONTEXT")
    channel_supervisor = ExARIExample.ChannelSupervisor
    config_module = Application.get_env(:ex_ari_example, :config_module)
    client_config = %{name: "ex_ari", module: ExARIExample.Client}
    router_config = Application.get_env(:ex_ari_example, :router)

    children = [
      ChannelRegistrar,
      {DynamicSupervisor, strategy: :one_for_one, name: channel_supervisor},
      {HTTP.Asterisk, [rest_host, rest_port, un, pw]},
      {HTTP.Channels, [rest_host, rest_port, un, pw]},
      {HTTP.Playbacks, [rest_host, rest_port, un, pw]},
      {HTTP.Recordings, [rest_host, rest_port, un, pw]},
      {HTTP.Events, [rest_host, rest_port, un, pw]},
      {Stasis, [channel_supervisor, client_config, ws_host, un, pw]},
      {Stasis, [channel_supervisor, router_config, ws_host, un, pw]},
      {Configurator, [name, transport, context, config_module]},
      {Plug.Cowboy, scheme: :http, plug: Router, options: [port: 4001, dispatch: dispatch()]}
    ]

    opts = [strategy: :one_for_one, name: ExARIExample.Supervisor]
    Supervisor.start_link(children, opts)
  end

  defp dispatch do
    [
      {:_,
       [
         {"/sound/[...]", :cowboy_static,
          {:dir, Path.join(:code.priv_dir(:ex_ari_example), "sounds"),
           [{:mimetypes, {<<"audio">>, <<"basic">>, []}}]}}
       ]}
    ]
  end
end
