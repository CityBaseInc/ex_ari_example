defmodule ExARIExample.Client do
  use GenServer
  require Logger
  alias ARI.HTTP.{Asterisk, Channels, Playbacks}
  alias ARI.Stasis
  @behaviour Stasis

  @sound_url "http://localhost:4001/sound/"

  defmodule State do
    defstruct [:channel, :caller, :start_event, :playback_id, input: ""]
  end

  @impl Stasis
  def state(channel, caller, _args, start_event, _app_config) do
    %State{
      channel: channel,
      caller: caller,
      start_event: start_event
    }
  end

  def start_link([state]) do
    GenServer.start_link(__MODULE__, state, name: __MODULE__)
  end

  @impl GenServer
  def init(state) do
    info = Asterisk.info()
    Logger.info("Asterisk Info: #{inspect(info.json)}")
    Process.send_after(self(), :welcome, 100)
    {:ok, state}
  end

  @impl GenServer
  def handle_info(:welcome, %State{channel: channel} = state) do
    id = play(channel, ["welcome", "language_input_es", "menu_options"])
    {:noreply, %State{state | playback_id: id}}
  end

  @impl GenServer
  def handle_info({:ari, %{type: "PlaybackStarted", playback: %{id: id}}}, state) do
    Logger.info("Playback started: #{id}")
    {:noreply, %State{state | playback_id: id}}
  end

  @impl GenServer
  def handle_info({:ari, %{type: "ChannelDtmfReceived", digit: "1"}}, state) do
    Playbacks.stop(state.playback_id)
    play(state.channel, "citybase_rules")
    {:noreply, %State{state | input: ""}}
  end

  @impl GenServer
  def handle_info({:ari, %{type: "ChannelDtmfReceived", digit: "2"}}, state) do
    Playbacks.stop(state.playback_id)
    play(state.channel, "account_lookup")
    {:noreply, %State{state | input: ""}}
  end

  @impl GenServer
  def handle_info(
        {:ari, %{type: "ChannelDtmfReceived", digit: digit}},
        %State{input: input} = state
      ) do
    state = %State{state | input: input <> digit}
    Logger.info("Touch tone data: #{inspect(state)}")
    {:noreply, state}
  end

  @impl GenServer
  def handle_info({:ari, %{} = event}, state) do
    Logger.info("Unhandled ARI event: #{inspect(event)}")
    {:noreply, state}
  end

  defp play(channel, sounds) when is_list(sounds) do
    id = UUID.uuid4()

    sounds =
      sounds
      |> Enum.map(&sound_url/1)
      |> Enum.join(",")

    Channels.play(channel, id, sounds)
    id
  end

  defp play(channel, sound) do
    play(channel, [sound])
  end

  defp sound_url(file) do
    "sound:" <> @sound_url <> file <> ".wav"
  end
end
