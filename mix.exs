defmodule ExARIExample.Mixfile do
  use Mix.Project

  def project do
    [
      app: :ex_ari_example,
      version: "0.1.0",
      elixir: "~> 1.9",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {ExARIExample.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:ex_ari, "~> 0.1"},
      {:plug, "~> 1.8"},
      {:plug_cowboy, "~> 2.1"}
    ]
  end
end
