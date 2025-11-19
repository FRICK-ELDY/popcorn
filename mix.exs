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
      # 本家デモ方式: eval 対応を得るため GitHub main を使用（将来は安定版に戻す）
      {:popcorn, github: "software-mansion/popcorn", branch: "main"}
    ]
  end
end


