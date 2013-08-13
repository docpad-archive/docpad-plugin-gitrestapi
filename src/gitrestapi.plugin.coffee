# Export Plugin
module.exports = (BasePlugin) ->
	# Requires
	pathUtil = require('path')
	gitpad = require('gitpad')

	# Define Plugin
	class GitRestAPI extends BasePlugin
		# Plugin name
		name: 'gitrestapi'

		# Plugin configuration
		config:
			channel: '/git'
			repositoryPath: null

		# DocPad Ready Event
		docpadReady: (opts, next) ->
			# Prepare
			docpad = @docpad
			config = @getConfig()
			docpadConfig = docpad.getConfig()
			repositoryPath = pathUtil.resolve(docpadConfig.rootPath, config.repositoryPath or '')

			# Initialise git repository
			gitpad.init repositoryPath, (err, status) ->
				docpad.log('err', 'Error initializing Git:', err)  if err
				docpad.log('debug', 'Git Status:', status)
				return next()

			# Chain
			@

		# Server Extend Event
		serverExtend: (opts) ->
			# Prepare
			docpad = @docpad
			config = @getConfig()
			{server} = opts

			server.all '#{config.channel}/:action/:file?', (req, res) ->
				# Prepare
				action = req.params.action
				fileRelativePath = req.params.file
				validActions = ['save', 'remove']

				# Aliases
				unless action
					if req.method is 'delete'
						action = 'remove'
					else
						action = 'save'
				else if action is 'update'
					action = 'save'
				else if action is 'delete'
					action = 'remove'

				# Ensure that we have valid parameters
				unless fileRelativePath
					return res.send(success: false, message: 'Please specify a file to perform an action against')
				unless action in validActions
					return res.send(success: false, message: 'Please specifiy a valid action to perform, these currently include: '+validActions.join(','))
				file = docpad.getFile(relativePath: fileRelativePath)
				unless file
					return res.send(success: false, message: 'That file does not exist')

				# Update are just saves
				gitAction = gitpad[action+'File']
				fileFullPath = file.get('fullPath')

				# Call gitpad
				gitAction fileFullPath, "User initiated #{action} on #{fileRelativePath}", (err, msg) ->
					# Check
					docpad.log('err', err)  if err

					# Send
					res.send(success: !err, message: err or "#{action} on #{fileRelativePath} completed successfully")

			# Chain
			@
