defmodule ExARIExample.Router do
  use Plug.Router
  import Plug.Conn

  plug(:match)
  plug(:dispatch)

  match _ do
    :ok
  end
end
