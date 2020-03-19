defmodule Appsignal.Phoenix.MixProject do
  use Mix.Project

  def project do
    [
      app: :appsignal_phoenix,
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
      mod: {Appsignal.Phoenix.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:appsignal_plug, github: "appsignal/appsignal-elixir-plug"}
    ]
  end
end