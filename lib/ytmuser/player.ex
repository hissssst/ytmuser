defmodule Ytmuser.Player do

  use GenServer
  require Logger

  @tick 1_000

  # API

  def open(filename) do
    GenServer.cast(__MODULE__, {:open, filename})
  end

  def next, do: GenServer.cast(__MODULE__, {:command, "next"})
  def stop, do: GenServer.cast(__MODULE__, {:command, "stop"})

  def list do
    GenServer.call(__MODULE__, :list)
  end

  def put_thumbnail(filename, thumbnail) do
    GenServer.cast(__MODULE__, {:put_thumbnail, filename, thumbnail})
  end

  # GenServer handlers

  def start_link(dir) do
    GenServer.start_link(__MODULE__, %{dir: dir, thumbnails: %{}}, name: __MODULE__)
  end

  def init(state) do
    with(
      path when is_binary(path) <- System.find_executable("vlc"),
      path when is_binary(path) <- System.find_executable("playerctl"),
      {_, 0} <- System.cmd("playerctl", ["loop", "Playlist"])
    ) do
      Process.send_after(self(), :tick, @tick)
      {:ok, state} 
    else
      {_, _} -> {:stop, "please start vlc and enable playerctl"}
      _ -> {:stop, "vlc or playerctl not found"}
    end
  end

  def handle_cast({:open, filename}, %{dir: dir} = state) do
    Logger.debug("#{__MODULE__} opening #{filename}")
    files = File.ls!(dir)
    if filename in files do
      command("open", "#{dir}/#{filename}")
    end
    Logger.debug("#{__MODULE__} finished opening #{filename}")
    {:noreply, state}
  end
  def handle_cast(
    {:put_thumbnail, filename, thumbnail}, 
    %{thumbnails: thumbnails} = state
  ) do
    {:noreply, %{state | thumbnails: Map.put(thumbnails, filename, thumbnail)}}  
  end
  def handle_cast({:command, comm}, state) do
    command(comm)
    {:noreply, state}
  end

  def handle_call(:list, _, %{dir: dir} = state) do
    res =
      File.ls!(dir)
      |> Enum.join("\n")
    {:reply, res, state}
  end

  def handle_info(:tick, %{thumbnails: thumbnails} = state) do
    file = get_file()
    player = %{
      status: get_status(),
      file: file,
      thumbnail: Map.get(thumbnails, file, "https://shiroganenosuiren.files.wordpress.com/2014/01/sakura-trick-3-4.jpg")
    }
    Ytmuser.Room.broadcast({:player, player})
    Process.send_after(self(), :tick, @tick)
    {:noreply, state}
  end

  defp command(arg) do
    System.cmd("playerctl", [arg])
  end

  defp command(option, arg) do
    System.cmd("playerctl", [option, arg])
  end

  def get_status() do
    System.cmd("playerctl", [
      "metadata",
      "--format",
      "{{ duration(position) }} - {{ duration(mpris:length) }}"
    ])
    |> case do
      {status, 0} ->
        String.trim(status)
      err ->
        Logger.error("#{__MODULE__} couldn't get status with #{inspect err}")
        ""
    end
    |> to_default("No status")
  end

  def get_file() do
    case System.cmd("playerctl", ["metadata", "--format", "{{ xesam:url }}"]) do
      {file, 0} ->
        file
        |> String.trim()
        |> String.split("/")
        |> List.last()
        |> URI.decode()
      err ->
        Logger.error("#{__MODULE__} couldn't get file with #{inspect err}")
        ""
    end
    |> to_default("No file")
  end

  def to_default("", default), do: default
  def to_default(str, _), do: str

end
