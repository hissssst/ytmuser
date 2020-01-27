defmodule Ytmuser.Ytdl do

  use GenServer
  alias Ytmuser.Message
  require Logger

  # API
  
  def load(url, msg) do
    GenServer.cast(__MODULE__, {:load, url, msg})
  end

  # GenServer handlers

  @spec start_link(binary()) :: {:ok, pid()} | {:error, any()}
  def start_link(directory) do
    GenServer.start_link(__MODULE__, %{dir: directory}, name: __MODULE__)
  end

  def init(state) do
    case System.find_executable("youtube-dl") do
      nil -> {:stop, "could not find youtube-dl"}
      _path -> {:ok, state}
    end
  end

  def handle_cast(
    {:load, url, msg},
    %{dir: dir} = state
  ) do

    Logger.info("#{__MODULE__} started loading #{url} into #{inspect msg}")

    # Directory before upload
    was = File.ls!(dir)

    # Loading file with streaming status into message
    System.cmd("/usr/local/bin/youtube-dl", [
      "-i", "-c",
      "--extract-audio",
      "--audio-format", "mp3",
      "--audio-quality", "0",
      "--no-playlist",
      "-o", "#{dir}/%(title)s.%(ext)s",
      url
    ], [
      into: msg,
      stderr_to_stdout: true
    ])
    |> case do
      {_, 0} ->
        [filename] = File.ls!(dir) -- was
        Message.change(msg, "Successfully loaded #{filename}")
        case get_thumbnail(url) do
          {:ok, thumbnail} ->
            Ytmuser.Player.put_thumbnail(filename, thumbnail)
          _ ->
            Logger.info("#{__MODULE__} couldn't get thumbnail for #{filename}")
        end

      {_, c} ->
        Message.change(msg, "Upload failed with #{c}")
    end
    {:noreply, state}
  end

  def get_thumbnail(url) do
    case System.cmd("/usr/local/bin/youtube-dl", ["--get-thumbnail", url]) do
      {str, 0} -> {:ok, String.trim(str)}
      other -> {:error, other}
    end
  end

end
