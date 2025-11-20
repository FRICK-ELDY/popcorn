defmodule PopcornDemo.Application do
  use Application

  @impl true
  def start(_type, _args) do
    children = [
			PopcornDemo.Worker,
			PopcornDemo.Ticker
    ]

    opts = [strategy: :one_for_one, name: PopcornDemo.Supervisor]
    Supervisor.start_link(children, opts)
  end
end


