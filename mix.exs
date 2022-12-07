defmodule StateChannel.MixProject do
  use Mix.Project

  @description "StateChannel allows you to store and modify front-end app state on the backend using Phoenix Channels"

  def project do
    [
      app: :state_channel,
      description: @description,
      version: "0.0.1",
      elixir: "~> 1.13",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      source_url: "https://github.com/amberbit/state_channel",
      homepage_url: "https://github.com/amberbit/state_channel",
      docs: [
        extras: ["README.md"]
      ],
      package: package()
    ]
  end

  defp package do
    [
      licenses: ["MIT"],
      links: %{
        "GitHub" => "https://github.com/amberbit/state_channel"
      },
      files: ~w(lib mix.exs mix.lock README.md LICENSE)
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
      {:jason, "~> 1.4", only: :test}
    ]
  end
end
