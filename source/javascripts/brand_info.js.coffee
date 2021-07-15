
FC.templater = (id) ->
  @container = $("##{id}")

  @result = () ->
    @container.children(".result")

  @template = () ->
    @container.children(".template")

  @publish = () ->
    @find('[data-toggle="popover"]').popover()
    @result().append @current

  @fill = (field, value) ->
    @find("._#{field}").text(value)

  @find = (selector) ->
    @current.find selector

  @result().empty()
  @current = @template().clone()
  @current.removeClass "template"
  this

FC.commitmentImage = (el, value) ->
  value = "Yes" if value.includes "Yes"
  FC.selectImage el, "smiley", value, "svg"

FC.transparencyImage = (el, val) ->
  return unless (stars = FC.score.transparency[val])
  current = 1
  while (current <= stars)
    img = el.find "._star-#{current}"
    FC.selectImage img, "transparency_score", "star_solid", "svg"
    current++

FC.selectImage = ($el, folder, score, ext) ->
  ext ||= "png"
  $el.attr("src", "/images/#{folder}/#{score}.#{ext}")

FC.wikirateUrl = (company_id) ->
  "#{FC.wikirate_link_target}/~#{company_id}?" +
    $.param(
      contrib: "N"
      filter: { wikirate_topic: "Filling the Gap" }
    )

FC.brandBox = (company_id) ->
  @company_id = company_id
  @template = new FC.templater "brandBox"

  @build = () ->
    @fillName()
    @fillSimple()
    @fillCommitments()
    @fillTranslations()
    @fillSubBrands()
    @livingWageImage()
    @transparency()
    @wikiRateLinks()
    @tweetTheBrand()
    @template.publish()

  @fillName = () ->
    @template.fill "brand_name", @data["name"]

  @fillCommitments = () ->
    for _i, fld of ["action_plan", "public_commitment", "isolating_labor"]
      @commitmentScore @template.current, fld, @value(fld)

  @commitmentScore = (el, name, value) ->
    el.find("._#{name}").text(value)
    letterGrade = FC.score.commitment[value]

    el.find("._#{name}-help").attr("data-target", "##{name}-score-#{letterGrade}")
    FC.commitmentImage el.find("._#{name}-smiley"), value

  @fillTranslations = () ->
    for _i, fld of ["transparency_key", "living_wages_key"]
      @template.fill fld, scoreTranslation[@value(fld)]

  @fillSubBrands = () ->
    subs = FC.subBrands[@data["name"]]
    return unless subs

    list = @find "._sub_brand_list"
    for _i, brand of subs
      list.append $("<li>#{brand}</li>")

  @fillSimple = () ->
    fields =
      ["headquarters", "revenue", "profit", "top_3_production_countries"]
    for _i, fld of fields
      @template.fill fld, @value(fld)

  @value = (fld) ->
    @data[FC.brands_metric_map[fld]]

  @interpret = (data) ->
    @data = FC.companies(data)[@company_id]

  @find = (key) ->
    @template.current.find key

  @livingWageImage = () ->
    fld = "living_wages_score"
    FC.selectImage @find("._#{fld}"), "wage_score", @value(fld)

  @transparency = () ->
    FC.transparencyImage @find("._transparency-stars"), @value("transparency_score")

  @wikiRateLinks = () ->
    @find("._wikirate-link").attr "href", FC.wikirateUrl(@company_id)

  @tweetTheBrand = () ->
    return unless (handle = @value "twitter_handle")

    link = @find "._tweet-the-brand"
    tweetText = "#{handle}\n#{window.location.href} #LivingWageNow"
    link.attr "href", link.attr("href") + $.param({ text: tweetText })
    link.removeClass("d-none")

  box = this
  url = FC.apiUrl "~#{@company_id}+Answer/compact",
    filter:
      metric_id: Object.values(FC.brands_metric_map)
      year: "latest"

  $.when(
    $.ajax url: url, dataType: "json"
    FC.loadSubBrands
  ).done (data) ->
    box.data = box.interpret data[0]
    box.build()
