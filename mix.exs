defmodule PopcornDemo.MixProject do
  use Mix.Project

  def project do
    [
      app: :popcorn_demo,
      version: "0.1.0",
      elixir: "~> 1.17",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  def application do
    [
      extra_applications: [],
      mod: {PopcornDemo.Application, []}
    ]
  end

  defp deps do
    [
      {:popcorn, "~> 0.1.0"}
    ]
  end
end


