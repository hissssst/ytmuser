defmodule Ytmuser.Room do

  use GenServer
  alias Ytmuser.Message
  alias Ytmuser.Player
  alias Ytmuser.Ytdl
  @name {:global, __MODULE__}

  @helpmessage """
  Avaliable commands are:
  :list
  :open [filename]
  :load [youtubeurl]
  """

  def start_link(_) do
    GenServer.start_link(__MODULE__, [], name: @name) 
  end

  def init(_) do
    # Create group for sharing stuff between clients
    :pg2.create(:clients)

    state = %{
      message_count: 100
    }
    {:ok, state}
  end

  def broadcast(msg) do
    :pg2.get_local_members(:clients)
    |> Enum.each(&send(&1, msg))
    msg
  end

  @spec new_message(binary(), Phoenix.LiveView.Socket.t()) :: any()
  def new_message(":help", %{root_pid: pid}) do
    system(@helpmessage, pid)
  end 
  def new_message(":list", %{root_pid: pid}) do
    system(Player.list, pid)
  end
  def new_message(":load " <> url, %{assigns: %{myname: author}}) do
    upload(url, author)
  end
  def new_message(":open " <> filename, _) do
    Player.open(filename)
    player("Opening #{filename}")
  end
  def new_message(message, %{assigns: %{myname: author}}) do
    chat(message, author)
  end

  def handle_call(:next, _, %{message_count: mc} = state) do
    {:reply, mc, %{state | message_count: mc + 1}}
  end

  def chat(msg, author) do
    msg = %Message{
      author: author,
      id: GenServer.call(@name, :next),
      text: msg
    }
    broadcast({:message, msg})
  end

  def system(msg, pid) do
    send(pid, {:message, Message.system(msg)})
  end

  def player(msg) do
    msg = %Message{
      id: 1,
      author: "Player",
      text: msg
    }
    broadcast({:message, msg})
  end

  def upload(url, author) do
    msg = %Message{
      author: author,
      id: GenServer.call(@name, :next),
      text: "Loading #{url}"
    }
    broadcast({:message, msg})
    Ytdl.load(url, msg)
  end

end
