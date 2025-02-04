defmodule Servy.Handler do

  @moduledoc "Handles HTTP requests."

  alias Mix.Dep.Fetcher
  alias Servy.Conv
  alias Servy.BearController
  alias Servy.Api.BearController, as: ApiBearController
  alias Servy.VideoCam

  @pages_path Path.expand("../../pages", __DIR__)

  import Servy.Plugins, only: [rewrite_path: 1, log: 1, track: 1]
  import Servy.Parser, only: [parse: 1]
  import Servy.View, only: [render: 3]

  @doc "Transforms the request into a response."
  def handle(request) do
    request
    |> parse
    |> rewrite_path
    |> route
    |> track
    |> put_content_length
    |> format_response
  end

  def route(%Conv{method: "GET", path: "/pledges/new"} = conv) do
    Servy.PledgeController.new(conv)
  end

  def route(%Conv{method: "GET", path: "/404s"} = conv) do
    counts = Servy.FourOhFourCounter.get_counts()

    %{ conv | status: 200, resp_body: inspect counts }
  end

  def route(%Conv{method: "GET", path: "/reset"} = conv) do
    counts = Servy.FourOhFourCounter.reset()

    %{ conv | status: 200, resp_body: inspect counts }
  end

  def route(%Conv{method: "POST", path: "/pledges"} = conv) do
    Servy.PledgeController.create(conv, conv.params)
  end

  def route(%Conv{method: "GET", path: "/pledges"} = conv) do
    Servy.PledgeController.index(conv)
  end

  def route(%Conv{ method: "GET", path: "/sensors" } = conv) do
    # task = Task.async(Servy.Tracker, :get_location, ["bigfoot"])

    # snapshots =
    #   ["cam-1", "cam-2", "cam-3"]
    #   |> Enum.map(&Task.async(fn -> VideoCam.get_snapshot(&1) end))
    #   |> Enum.map(&Task.await/1)

    # where_is_bigfoot =
    #   case Task.yield(task, :timer.seconds(5)) do
    #     {:ok, result} ->
    #       result
    #     nil ->
    #       Logger.warn "Timed out!"
    #       Task.shutdown(task)
    #   end

    # render(conv, "sensors.eex", snapshots: snapshots, location: where_is_bigfoot)

    sensor_data = Servy.SensorServer.get_sensor_data()

    %{ conv | status: 200, resp_body: inspect sensor_data }
  end

  def route(%Conv{ method: "GET", path: "/kaboom" } = conv) do
    raise "Kaboom!"
  end

  def route(%Conv{ method: "GET", path: "/hibernate/" <> time} = conv) do
    time |> String.to_integer |> :timer.sleep

    %{ conv | status: 200, resp_body: "Awake!" }
  end

  # @spec route(%{
  #         :method => <<_::24, _::_*8>>,
  #         :path => <<_::48, _::_*8>>,
  #         optional(any()) => any()
  #       }) :: map()
  # def route(conv) do
  #   IO.puts "7"

  #   route(conv, conv.method, conv.path)
  # end

  def route(conv, "DELETE", "/bears/" <> _id) do
    BearController.delete(conv, conv.params)
  end

  def route(conv, "GET", "/wildthings") do
    %{ conv | status: 200, resp_body: "Bears, Lions, Tigers" }
  end

  def route(conv, "GET", "/api/bears") do
    Servy.Api.BearController.index(conv)
  end

  def route(conv, "GET", "/bears") do
    BearController.index(conv)
  end

  def route(conv, "GET", "/bears/" <> id) do
    params = Map.put(conv.params, "id", id)
    BearController.show(conv, params)
  end

  def route(conv, "POST", "/bears") do
    BearController.create(conv, conv.params)
  end

  def route(conv, "POST", "/api/bears") do
    ApiBearController.create(conv, conv.params)
  end

  def route(conv, "GET", "/pages" <> name) do
    @pages_path
      |> Path.join("#{name}")
      |> File.read
      |> handle_file(conv)
      |> markdown_to_html
  end

  def route(conv, "GET", "/about") do
      @pages_path
      |> Path.join("about.html")
      |> File.read
      |> handle_file(conv)
  end

  def route(%Conv{path: path} = conv) do
    %{ conv | status: 404, resp_body: "No #{path} here!"}
  end

  def handle_file({:ok, content}, conv) do
    %{ conv | status: 200, resp_body: content }
  end

  def handle_file({:error, :enoent}, conv) do
    %{ conv | status: 404, resp_body: "File not found!" }
  end

  def handle_file({:error, reason}, conv) do
    %{ conv | status: 500, resp_body: "File error: #{reason}" }
  end

  def markdown_to_html(%Conv{status: 200} = conv) do
    %{ conv | resp_body: Earmark.as_html!(conv.resp_body) }
  end

  def markdown_to_html(%Conv{} = conv), do: conv

  def put_content_length(conv) do
    headers = Map.put(conv.resp_headers, "Content-Length", String.length(conv.resp_body))
    %{conv | resp_headers: headers}
  end

  def format_response_headers(conv) do

    for {header_key, header_value} <- conv.resp_headers do
      "#{header_key}: #{header_value}\r"
    end |> Enum.sort |> Enum.reverse |> Enum.join("\n")
  end


  def format_response(%Conv{} = conv) do
    """
    HTTP/1.1 #{Conv.full_status(conv)}\r
    #{format_response_headers(conv)}
    \r
    #{conv.resp_body}
    """
  end

end
