define ['params!', 'd3', 'e2d3model', 'e2d3util'], (params, d3, model, util) ->
  ChartDataTable = model.ChartDataTable

  ###
  # Excel API
  ###
  class Binding
    constructor: (@binding) ->

    on: (event, handler) ->
      if event == 'change'
        @binding.addHandlerAsync Office.EventType.BindingDataChanged, handler

    fetchData: () ->
      new Promise (resolve, reject) =>
        @binding.getDataAsync valueFormat: Office.ValueFormat.Formatted, (result) ->
          if result.status == Office.AsyncResultStatus.Succeeded
            resolve new ChartDataTable result.value
          else
            resolve new ChartDataTable []

    release: () ->
      new Promise (resolve, reject) =>
        Office.context.document.bindings.releaseByIdAsync @binding.id, (result) =>
          if result.status == Office.AsyncResultStatus.Succeeded
            delete @binding
            resolve()
          else
            reject result.error

  class ExcelAPI
    fill: (type, text, callback) ->
      new Promise (resolve, reject) ->
        rows = d3[type].parseRows text

        Office.context.document.setSelectedDataAsync rows, coercionType: Office.CoercionType.Matrix, (result) ->
          if result.status == Office.AsyncResultStatus.Succeeded
            resolve()
          else
            reject result.error

    bindSelected: (callback) ->
      new Promise (resolve, reject) ->
        Office.context.document.bindings.addFromSelectionAsync Office.BindingType.Matrix, (result) ->
          if result.status == Office.AsyncResultStatus.Succeeded
            resolve new Binding result.value
          else
            reject result.error

    bindPrompt: (callback) ->
      new Promise (resolve, reject) ->
        Office.context.document.bindings.addFromPromptAsync Office.BindingType.Matrix, (result) ->
          if result.status == Office.AsyncResultStatus.Succeeded
            resolve new Binding result.value
          else
            reject result.error

  ###
  # Dummy API
  ###
  class DummyBinding
    constructor: (@data) ->

    on: (event, handler) ->

    fetchData: () ->
      new Promise (resolve, reject) =>
        resolve new ChartDataTable @data

    release: () ->
      new Promise (resolve, reject) ->
        resolve()

  class DummyExcelAPI
    fill: (type, text, callback) ->
      new Promise (resolve, reject) ->
        @rows = d3[type].parseRows text
        resolve()

    bindSelected: (callback) ->
      new Promise (resolve, reject) ->
        resolve new DummyBinding @rows

  ###
  # export
  ###
  initialize: () ->
    if util.isExcel()
      new ExcelAPI()
    else
      new DummyExcelAPI()
