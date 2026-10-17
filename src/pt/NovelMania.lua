-- {"id":55001,"ver":"1.0.0","libVer":"1.0.0","author":"Custom","dep":[]}

local baseURL = "https://novelmania.com.br"

--- Encurtador de URL obrigatório pelo Shosetsu
local function shrinkURL(url, _)
	return url:gsub("^https?://novelmania%.com%.br", "")
end

--- Expansor de URL obrigatório pelo Shosetsu
local function expandURL(url, _)
	if url:find("^https?://") then
		return url
	end
	return baseURL .. url
end

--- Extrai o texto do capítulo
local function getPassage(chapterURL)
	local fullURL = expandURL(chapterURL)
	local doc = RequestDocument(fullURL)
	local content = doc:selectFirst(".rich-text-content")
	if content then
		local paragraphs = content:select("p")
		local textList = ArrayList()
		for i = 0, paragraphs:size() - 1 do
			local p = paragraphs:get(i):text()
			if p and p ~= "" then
				textList:add(p)
			end
		end
		local result = ""
		for i = 0, textList:size() - 1 do
			if i > 0 then result = result .. "\n\n" end
			result = result .. textList:get(i)
		end
		return result
	end
	return ""
end

--- Extrai os detalhes da novel e a lista de capítulos
local function parseNovel(novelURL)
	local fullURL = expandURL(novelURL)
	local doc = RequestDocument(fullURL)
	local novel = NovelInfo()

	local title = doc:selectFirst("h1")
	if title then novel.title = title:text() end

	local cover = doc:selectFirst("aside img")
	if cover then novel.imageURL = cover:attr("src") end

	local synopsis = doc:selectFirst("[data-testid=novel-synopsis]")
	if synopsis then novel.description = synopsis:text() end

	local authorEl = doc:selectFirst("dt:contains(Autor) + dd")
	if authorEl then
		local authors = ArrayList()
		authors:add(authorEl:text())
		novel.authors = authors
	end

	local chapterLinks = doc:select("a[href*=/capitulos/]")
	local chapters = ArrayList()

	for i = 0, chapterLinks:size() - 1 do
		local a = chapterLinks:get(i)
		local href = a:attr("href")
		local titleEl = a:selectFirst("span")
		local chapTitle = titleEl and titleEl:text() or ("Capítulo " .. (i + 1))

		local chap = Chapter()
		chap.url = href
		chap.title = chapTitle
		chap.order = i + 1
		chapters:add(chap)
	end

	novel.chapters = chapters
	return novel
end

--- Pesquisa novels
local function search(filters, reporter)
	local query = filters[QUERY] or ""
	local searchURL = baseURL .. "/novels"
	if query ~= "" then
		searchURL = searchURL .. "?q=" .. query
	end

	local doc = RequestDocument(searchURL)
	local novels = ArrayList()

	local items = doc:select("article a[href^=/novels/]")
	for i = 0, items:size() - 1 do
		local a = items:get(i)
		local novel = Novel()
		novel.link = a:attr("href")

		local img = a:selectFirst("img")
		if img then novel.imageURL = img:attr("src") end

		local p = a:selectFirst("p")
		if p then novel.title = p:text() end

		novels:add(novel)
	end

	return novels
end

return {
	id = 55001,
	name = "Novel Mania",
	baseURL = baseURL,
	imageURL = "https://novelmania.com.br/logo512.png",
	hasCloudFlare = false,
	hasSearch = true,
	shrinkURL = shrinkURL,
	expandURL = expandURL,
	parseNovel = parseNovel,
	getPassage = getPassage,
	search = search
}
