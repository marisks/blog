strip = require("strip-markdown")
remark = require("remark")

strip_md = (value) ->
  remark().use(strip).processSync(value).toString().trim()

# The DocPad Configuration File
# It is simply a CoffeeScript Object which is parsed by CSON
docpadConfig = {
	# =================================
	# Template Data
	# These are variables that will be accessible via our templates
	# To access one of these within our templates, refer to the FAQ: https://github.com/bevry/docpad/wiki/FAQ

	templateData:

		# Specify some site properties
		site:
			# The production url of our website
			url: "http://marisks.net"

			# The default title of our website
			title: "marisks # code"

			# The website description (for SEO)
			description: """
					blog about .NET, JavaScript, Web, Optimizely (ex Episerver) and programming languages
				"""

			# The website keywords (for SEO) separated by commas
			keywords: """
				.NET, ASP.NET, C#, JavaScript, Optimizely, EPiServer, programming languages
				"""

			# The website's styles
			styles: [
				'/css/vendor/normalize.css'
							'/css/vendor/main.css'
							'/css/vendor/bootstrap.min.css'
							'//netdna.bootstrapcdn.com/font-awesome/4.0.3/css/font-awesome.css'
				'/css/style.css'
			]

			# The website's scripts
			scripts: [
				'/bower_components/bootstrap/dist/js/bootstrap.min.js'
				'/js/plugins.js'
				'/js/main.js'
			]

			meta: [
			]


		# -----------------------------
		# Helper Functions

		# Get the prepared site/document title
		# Often we would like to specify particular formatting to our page's title
		# we can apply that formatting here
		getPreparedTitle: ->
			# if we have a document title, then we should use that and suffix the site's title onto it
			if @document.title
				"#{@document.title} | #{@site.title}"
			# if our document does not have it's own title, then we should just use the site's title
			else
				@site.title

		# Get the prepared site/document description
		getPreparedDescription: ->
			# if we have a document description, then we should use that, otherwise use the site's description
			strip_md(@document.description) or @site.description

		# Get the prepared site/document keywords
		getPreparedKeywords: ->
			# Merge the document keywords with the site keywords
			@site.keywords.concat(@document.keywords or []).join(', ')
		isCurrent: (y,isRoot) ->
			if @document.url.indexOf('/'+y) is 0 then 'active'
			else if isRoot and @document.url.indexOf('/index') is 0 then 'active'
			else ''

	collections:
		posts: ->
			@getCollection("documents").findAllLive({relativeDirPath: 'posts'}, [date: -1])
				.setFilter 'visible', (model) ->
					visible = model.get('visible')
					if visible? then visible else true

		optimizelyPosts: ->
			@getCollection("documents").findAllLive({relativeDirPath: 'posts'}, [date: -1])
				.setFilter 'visible', (model) ->
					visible = model.get('visible')
					if visible? then visible else true
				.setFilter 'tags', (model) ->
					tags = model.get('tags')
					return false unless tags? and Array.isArray(tags)
					for tag in tags
						if tag.toLowerCase() is 'episerver' or tag.toLowerCase() is 'optimizely' then return true
					false


	# =================================
	# DocPad Events

	# Here we can define handlers for events that DocPad fires
	# You can find a full listing of events on the DocPad Wiki
	events:

		# Server Extend
		# Used to add our own custom routes to the server before the docpad routes are added
		serverExtend: (opts) ->
			# Extract the server from the options
			{server} = opts
			docpad = @docpad

			# As we are now running in an event,
			# ensure we are using the latest copy of the docpad configuraiton
			# and fetch our urls from it
			latestConfig = docpad.getConfig()
			oldUrls = latestConfig.templateData.site.oldUrls or []
			newUrl = latestConfig.templateData.site.url

			# Redirect any requests accessing one of our sites oldUrls to the new site url
			server.use (req,res,next) ->
				if req.headers.host in oldUrls
					res.redirect(newUrl+req.url, 301)
				else
					next()

	plugins:
		dateurls:
			cleanurl: true
			trailingSlashes: true

		cleanurls:
			collectionName: 'posts'

		ghpages:
			deployRemote: 'target'
			deployBranch: 'master'

		rss:
			default:
				collection: 'posts'
				url: '/rss.xml'
			episerver:
				collection: 'optimizelyPosts'
				url: '/episerver-rss.xml'
}

# Export our DocPad Configuration
module.exports = docpadConfig
