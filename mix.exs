defmodule Servy.Mixfile do
  use Mix.Project

  def project do
    [
      app: :servy,
      version: "0.1.0",
      elixir: "~> 1.14",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger, :eex]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:poison, "~> 6.0"},
      {:faker, "~> 0.18.0"},
      {:earmark, "~> 1.4"}
    ]
  end
end
