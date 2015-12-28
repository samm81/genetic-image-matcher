fs     = require 'fs'
path   = require 'path'
{exec} = require 'child_process'

# Make sure we have our dependencies
try
	colors = require 'colors'
catch error
	console.error 'Please run `npm install colors` first. For global install, use `npm install -g colors`.'
	process.exit 1

# Command line options for parameterized Cake tasks
options =
	sourceDir: null
	outputDir: null
	deployDir: null

option '-s', '--source [DIR]', 'CoffeeScript source folder'
option '-o', '--output [DIR]', 'JavaScript output folder'
option '-d', '--deploy [DIR]', 'Deployment location to optionally copy the compiled JavaScript into'

# Parameterized watch and deploy task.
# Can be run from command line with options, e.g.: cake -s ../coffee -o ../app -d ../deployfolder watchany
task 'watchany', 'Accepts paths as command line options. Automatically recompile CoffeeScript files to JavaScript.', ( opts ) ->
	options.sourceDir = opts?.source
	options.outputDir = opts?.output
	options.deployDir = opts?.deploy

	if( options.sourceDir? and options.outputDir? )

		console.log( "Common Cakefile executing...".yellow )
		console.log( "Watching coffee files in #{ options.sourceDir } for changes and compiling to #{ options.outputDir }".yellow )
		console.log( "Deploying compiled files to #{ options.deployDir }".yellow ) if options.deployDir?
		console.log( "Press Control-C to quit".yellow )

		srcDeployer  = exec "coffee --compile --bare --watch --output #{ options.deployDir } #{ options.sourceDir }" if options.deployDir?
		srcWatcher  = exec "coffee --compile --bare --watch --output #{ options.outputDir } #{ options.sourceDir }"

		srcWatcher.stderr.on 'data', ( data ) -> console.error stripEndline(data).red.bold

		srcWatcher.stdout.on 'data', ( data ) ->
			if /compiled/.test data
				process.stdout.write prependFileName( data ).green
			else
				process.stderr.write prependFileName( data ).red.bold

	else
		console.error( stripEndline( "You must pass command options for source and output directories" ).red.bold )
		console.error( stripEndline( "e.g.: cake -s ../coffee -o ../app watch" ).red.bold )
		console.error( stripEndline( "Type 'cake' for a full list of tasks and options." ).red.bold )

# Helper for formatting process output with file name prepended
prependFileName = ( str ) ->
	lines = str.split( "\n" )
	result = ""

	for line in lines
		pathOsNeutral = line.replace( /\//g, '\\' )
		pathArray = pathOsNeutral.split( '\\' )
		fileName = stripEndline( pathArray[ pathArray.length-1 ] )
		result += "#{ fileName }: #{ line }\n" if fileName?.length and line?.length

	return result

# Helper for stripping trailing endline when outputting
stripEndline = ( str ) ->
	return if str[ str.length - 1 ] is "\n" then str.slice( 0, str.length - 1 ) else str

# Helper for stripping initial endline when outputting
stripStartline = ( str ) ->
	return if str[ 0 ] is "\n" then str.slice( 1, str.length ) else str
