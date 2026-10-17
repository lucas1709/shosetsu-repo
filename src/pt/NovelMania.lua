-- {"id":55001,"ver":"1.0.0","libVer":"1.0.0","author":"Custom","dep":[]}

local baseURL = "https://novelmania.com.br"

--- Extrai o texto do capítulo
--- @param chapterURL string
--- @return string
local function getPassage(chapterURL)
	local fullURL = chapterURL
	if not chapterURL:find("^https?://") then
		fullURL = baseURL .. chapterURL
	end

	local doc = RequestDocument(fullURL)
	local content = doc:selectFirst(".rich-text-content")
	if content then
		-- Retorna o texto formatado dos parágrafos
		local paragraphs = content:select("p")
		local textList = ArrayList()
		for i = 0, paragraphs:size() - 1 do
			local p = paragraphs:get(i):text()
			if p and p ~= "" then
				textList:add(p)
			end
		end
		-- Junta os parágrafos com quebra dupla de linha
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
--- @param novelURL string
--- @return NovelInfo
local function parseNovel(novelURL)
	local fullURL = novelURL
	if not novelURL:find("^https?://") then
		fullURL = baseURL .. novelURL
	end

	local doc = RequestDocument(fullURL)
	local novel = NovelInfo()

	-- Título
	local title = doc:selectFirst("h1")
	if title then
		novel.title = title:text()
	end

	-- Capa
	local cover = doc:selectFirst("aside img")
	if cover then
		novel.imageURL = cover:attr("src")
	end

	-- Sinopse
	local synopsis = doc:selectFirst("[data-testid=novel-synopsis]")
	if synopsis then
		novel.description = synopsis:text()
	end

	-- Autor
	local authorEl = doc:selectFirst("dt:contains(Autor) + dd")
	if authorEl then
		local authors = ArrayList()
		authors:add(authorEl:text())
		novel.authors = authors
	end

	-- Capítulos
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

--- Pesquisa novels no catálogo
--- @param filters table
--- @param reporter fun(v : string | any)
--- @return Novel[]
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
		if img then
			novel.imageURL = img:attr("src")
		end

		local p = a:selectFirst("p")
		if p then
			novel.title = p:text()
		end

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
	parseNovel = parseNovel,
	getPassage = getPassage,
	search = search
}
