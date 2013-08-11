# Export Plugin
module.exports = (BasePlugin) ->
	# Define Plugin
	gitpad = require('gitpad')
	userDir = ''

	class GitRestAPI extends BasePlugin
		# Plugin name
		name: 'gitrestapi'
		config:
			path: '/git/'
			debug: false

		docpadReady: (opts, next) ->
			docpad = @docpad
			docpadConfig = docpad.getConfig()
			userDir = docpadConfig.documentsPaths[0]
			that = @

			gitpad.init userDir, (err, status) ->
				console.log 'Error initializing Git: ' + err  if err
				console.log 'Git Status:\n' + JSON.stringify(status) + '\n'  if that.config.debug and status
				next()

			#Chain
			@

		serverExtend: (opts) ->
			docpad = @docpad
			docpadConfig = docpad.getConfig()
			server = opts.server

			server.post @config.path + ':action/:file?', (req, res) ->
				origAction = action = req.params.action
				file = req.params.file

				#Ensure that we have valid parameters
				validActions = ['save', 'update', 'remove']
				unless action
					res.send(success: false, message: 'Please specifiy an action to perform')
				unless action in validActions
					return res.send(success: false, message: 'Please specifiy a valid action to perform, these currently include \'' + validActions.join('\', \'') + '\'')
				unless file and docpad.getFile(relativePath: file)
					return res.send(success: false, message: 'That file does not exist')

				#Update are just saves
				action = 'save'  if action == 'update'

				#Call gitpad
				gitpad[action + 'File'] userDir + '/' + file, 'User initiated ' + origAction + ' of ' + file, (err, msg) ->
					console.log err  if err
					res.send(success: !err, message: err or 'Action [\'' + origAction + '\'] completed successfully')
			#Chain
			@