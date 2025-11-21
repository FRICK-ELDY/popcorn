defmodule PopcornDemo.Application do
  use Application

  @impl true
  def start(_type, _args) do
    children =
			case System.get_env("OSC_BRIDGE") do
				"1" ->
					[
						PopcornDemo.Web.Server
					]
				_ ->
					[
						PopcornDemo.Worker,
						PopcornDemo.Ticker
					]
			end

    opts = [strategy: :one_for_one, name: PopcornDemo.Supervisor]
    Supervisor.start_link(children, opts)
  end
end


