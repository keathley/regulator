defmodule Regulator.Telemetry do
  @moduledoc """
  Regulator produces multiple telemetry events.

  ## Events

  * `[:regulator, :limit]` - Returns the calculated limit

    #### Measurements
      * `:limit` - The new limit

    #### Metadata
      * `:regulator` - The name of the regulator

  * `[:regulator, :ask, :start]` - Is called when asking for access to a protected service

    #### Measurements
      * `:inflight` - The current inflight requests
      * `:system_time` - The current, monotonic system time

    #### Metadata
      * `:regulator` - The regulator name

  * `[:regulator, :ask, :stop]` - Called immediately before an `ask` call returns.

    #### Measurements
      * `:duration` - The amount of time taken in the regulator

    #### Metadata
      * `:regulator` - The name of the regulator
      * `:result` - The result of the call, either `:ok`, `:dropped`, `:error`, or `:ignore`

  * `[:regulator, :ask, :exception]` - Called if the callback passed to `ask` raises or throws

    #### Measurements
      * `:duration` - The amount of time taken in the regulator

    #### Metadata
      * `:kind` - The type of error
      * `:error` - The error
      * `:stacktrace` - The stacktrace
      * `:regulator` - The regulator name
  """

  @doc false
  def start(name, meta, measurements \\ %{}) do
    time = System.monotonic_time()
    measures = Map.put(measurements, :system_time, time)
    :telemetry.execute([:regulator, name, :start], measures, meta)
    time
  end

  @doc false
  def stop(name, start_time, meta, measurements \\ %{}) do
    end_time = System.monotonic_time()
    measurements = Map.merge(measurements, %{duration: end_time - start_time})

    :telemetry.execute(
      [:regulator, name, :stop],
      measurements,
      meta
    )
  end

  @doc false
  def exception(event, start_time, kind, reason, stack, meta \\ %{}, extra_measurements \\ %{}) do
    end_time = System.monotonic_time()
    measurements = Map.merge(extra_measurements, %{duration: end_time - start_time})

    meta =
      meta
      |> Map.put(:kind, kind)
      |> Map.put(:error, reason)
      |> Map.put(:stacktrace, stack)

    :telemetry.execute([:regulator, event, :exception], measurements, meta)
  end

  @doc false
  def event(name, metrics, meta) do
    :telemetry.execute([:regulator, name], metrics, meta)
  end
end
