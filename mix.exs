defmodule StateChannel.MixProject do
  use Mix.Project

  def project do
    [
      app: :state_channel,
      version: "0.1.0",
      elixir: "~> 1.13",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:phoenix, ">= 1.6.0"},
      {:json_patch, "~> 0.8"},
      {:json_diff, "~> 0.1"},
      {:jason, "~> 1.4", only: :test},
    ]
  end
end
