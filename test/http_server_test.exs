defmodule HttpServerTest do
  use ExUnit.Case

  alias Servy.HttpServer

  test "accepts a request on a socket and sends back a response" do

    spawn(HttpServer, :start, [4014])

    urls = [
      "http://localhost:4014/wildthings",
      "http://localhost:4014/bears",
      "http://localhost:4014/bears/1",
      "http://localhost:4014/wildlife",
      "http://localhost:4014/api/bears"
    ]

    urls
    |> Enum.map(fn url -> Task.async(fn -> HTTPoison.get(url) end) end)
    |> Enum.map(fn task -> Task.await(task) end)
    |> Enum.map(&assert_successful_response/1)
    end

    defp assert_successful_response({:ok, response}) do
      assert response.status_code == 200
      #assert response.body == "Bears, Lions, Tigers"
  end
end
