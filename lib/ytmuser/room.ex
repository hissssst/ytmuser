defmodule Ytmuser.Room do

  use GenServer
  @name {:global, __MODULE__}

  def start_link(_) do
    GenServer.start_link(__MODULE__, [], name: @name) 
  end

  def init(_) do
    state = %{
      message_count: 0
    }
    {:ok, state}
  end

  @spec new_message(binary()) :: any()
  def new_message(":help"), do: system("this is help!")
  def new_message(message) do
    chat(message)
  end

  def handle_call(:next, _, %{message_count: mc} = state) do
    {:reply, mc, %{state | message_count: mc + 1}}
  end

  def chat(msg) do
    msg = %{
      span: "xxx",
      id: GenServer.call(@name, :next),
      text: msg
    }
    {:all, msg}
  end

  def system(msg) do
    msg = %{
      span: "System",
      id: GenServer.call(@name, :next),
      text: msg
    }
    {:self, msg}
  end

end
