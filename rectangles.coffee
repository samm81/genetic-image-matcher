class ImageMatcher
  @size = 256

  constructor: (imageurl, numRectangles, numGenes) ->
    body = document.getElementById("canvases")
    @bestScoreField = document.getElementById("bestScore")
    @iterationField = document.getElementById("iteration")
    target = document.getElementById("target").getContext("2d")
    img = new Image()
    img.crossOrigin = "anonymous"
    img.src = imageurl
    img.onload = () =>
      target.drawImage img, 0, 0
      @scorer = new Scorer target

    @canvases = []
    @scoredImages = []
    @rectangleCollections = []
    for i in [1..numGenes]
      canvas = document.createElement "canvas"
      canvas.setAttribute "width", 255
      canvas.setAttribute "height", 255
      canvas.setAttribute "id", "canvas#{i}"
      body.appendChild(canvas)
      @canvases.push canvas

      g = canvas.getContext "2d"
      rectangleCollection = new RectangleCollection (Binary.random numRectangles * Rectangle.bitCount), g
      @rectangleCollections.push rectangleCollection
      @scoredImages.push [0, rectangleCollection]

    breeder = new Breeder
    @looseGraphics = []
    @iteration = 0;

  run: () ->
    @updateDisplays()
    @recomputeScores()

    @bestScoreField.innerText = @findBestScore()
    @iterationField.innerText = @iteration  

    @killWorst()
    @killWorst()

    @breedRandomTwo()

    @mutateOne()

    #console.log "#{@iteration}:  #{bestScore}"
    #console.log @iteration
    #console.log @scoredImages
    #console.log ""

    @iteration++

  updateDisplays: () ->
    scoreImagePair[1].drawSelf() for scoreImagePair in @scoredImages

  recomputeScores: () ->
    @scoredImages = []
    @scoredImages.push [(@scorer.score rectangleCollection.getGraphics()), rectangleCollection] for rectangleCollection in @rectangleCollections

  killWorst: () ->
    worstIndex = 0
    worstScore = 0
    for pair, i in @scoredImages
      if pair[0] > worstScore
        worstScore = pair[0]
        worstIndex = i
    @scoredImages.splice worstIndex, 1
    @looseGraphics.push @rectangleCollections[worstIndex].getGraphics()
    @rectangleCollections.splice worstIndex, 1

  breedRandomTwo: () ->
    index1 = index2 = Math.floor(Math.random() * @scoredImages.length)
    index2 = Math.floor(Math.random() * @scoredImages.length) until index2 isnt index1

    parent1 = @rectangleCollections[index1]
    parent2 = @rectangleCollections[index2]
    child1 = new RectangleCollection (Breeder.breed parent1.getBinary(), parent2.getBinary()), @looseGraphics.pop()
    child2 = new RectangleCollection (Breeder.breed parent2.getBinary(), parent1.getBinary()), @looseGraphics.pop()

    @rectangleCollections.push child1
    @rectangleCollections.push child2
    @scoredImages.push [0, child1]
    @scoredImages.push [0, child2]

  mutateOne: () ->
    index = Math.floor(Math.random() * @scoredImages.length)
    mutatee = @rectangleCollections[index]
    mutated = new RectangleCollection (Breeder.mutate mutatee.getBinary()), mutatee.getGraphics()

    @rectangleCollections[index] = mutated
    @scoredImages[index] = [0, mutated]

  findBestScore: () ->
    bestScore = Number.MAX_VALUE
    for pair in @scoredImages
      if pair[0] < bestScore
        bestScore = pair[0]
    bestScore

  getBestRectangleCollectionIndex: () ->
    bestIndex = 0
    bestScore = Number.MAX_VALUE
    for pair, i in @scoredImages
      if pair[0] < bestScore
        bestScore = pair[0]
        bestIndex = i
    bestIndex

class Rectangle
  varBitCount = 8
  @bitCount = 8 * varBitCount

  constructor: (binary) ->
    @b = Binary.toInt binary[-varBitCount..]
    binary = Binary.shiftRight binary, varBitCount
    @g = Binary.toInt binary[-varBitCount..]
    binary = Binary.shiftRight binary, varBitCount
    @r = Binary.toInt binary[-varBitCount..]
    binary = Binary.shiftRight binary, varBitCount
    a = Binary.toInt binary[-varBitCount..]
    @a = a / 255
    binary = Binary.shiftRight binary, varBitCount

    @ybar = Binary.toInt binary[-varBitCount..]
    binary = Binary.shiftRight binary, varBitCount
    @xbar = Binary.toInt binary[-varBitCount..]
    binary = Binary.shiftRight binary, varBitCount
    @y = Binary.toInt binary[-varBitCount..]
    binary = Binary.shiftRight binary, varBitCount
    @x = Binary.toInt binary[-varBitCount..]

  drawSelf: (g) ->
    g.fillStyle = "rgba(#{@r}, #{@g}, #{@b}, #{@a})"
    width = @xbar - @x
    height = @ybar - @y
    g.fillRect @x, @y, width, height

  printSelf: () ->
    console.log "x: #{@x}, y: #{@y}, xbar: #{@xbar}, ybar: #{@ybar}"
    console.log "r: #{@r}, g: #{@g}, b: #{@b}, a: #{@a}, "

class RectangleCollection
  size = 256
  magnitude = 0

  constructor: (@binary, @g) ->
    binary = @binary
    @rectangles = []

    until binary.length is 0
      rectangleBinary = binary[-Rectangle.bitCount..]
      @rectangles.push new Rectangle rectangleBinary
      binary = Binary.shiftRight binary, Rectangle.bitCount
      magnitude++

    @rectangles.reverse()

  getGraphics: () -> @g

  getBinary: () -> @binary

  drawSelf: () ->
    @g.clearRect 0, 0, size, size
    rectangle.drawSelf @g for rectangle in @rectangles

  printSelf: () ->
    console.log "magnitude: #{magnitude}"
    for rectangle, i in @rectangles
      console.log "rectangle #{i}" 
      rectangle.printSelf()

class Scorer
  constructor: (base) ->
    @standardColors = (base.getImageData 0, 0, ImageMatcher.size, ImageMatcher.size).data

  score: (graphics) ->
    imageColors = (graphics.getImageData 0, 0, ImageMatcher.size, ImageMatcher.size).data
    score = 0
    score += Math.abs(imageColors[i] - @standardColors[i]) for i in [0...imageColors.length] when i % 4 isnt 3
    score

class Breeder
  constructor: () ->

  @breed: (parent1, parent2) ->
    bitLength = parent1.length
    splitPoint = Math.floor(Math.random() * bitLength)
    parent1[...splitPoint].concat parent2[splitPoint..]

  @mutate: (gene) ->
    bitLength = gene.length
    flipPoint = Math.floor(Math.random() * bitLength)
    bit = gene[flipPoint]
    gene[flipPoint] = if bit is 1 then 0 else 1
    gene

class Binary
  @shiftLeft: (b, num) ->
    b.concat (0 for i in [1..num])
  @shiftRight: (b, num) ->
    b[0...-num]
  @normalize: (b1, b2) ->
    if b1.length > b2.length
      b2 = (0 for i in [b2.length...b1.length]).concat b2
    else if b2.length > b1.length
      b1 = (0 for i in [b1.length...b2.length]).concat b1
    [b1, b2]
  @and: (b1, b2) ->
    [b1, b2] = @normalize b1, b2
    (b1[i] and b2[i] for i in [0...b1.length])
  @or: (b1, b2) ->
    [b1, b2] = @normalize b1, b2
    (b1[i] or b2[i] for i in [0...b1.length])
  @toInt: (b) ->
    parseInt(b.join(""), 2)
  @random: (numbits) ->
    ((if Math.random() < .5 then 1 else 0) for i in [1..numbits])

imageMatcher = null
go = () ->
  numRectangles = document.getElementById("numrectangles").value
  numGenes = document.getElementById("numgenes").value
  imageURL = document.getElementById("imageurl").value
  imageMatcher = new ImageMatcher imageURL, numRectangles, numGenes
  document.getElementById("instantiation").hidden = "true"
  setTimeout (() -> start()), 1000

start = () -> setInterval (() -> imageMatcher.run()), 0

saveImage = () ->
  index = imageMatcher.getBestRectangleCollectionIndex() + 1
  dataURL = document.getElementById("canvas#{index}").toDataURL()
  document.getElementById("snapshot").src = dataURL

document.getElementById("save").onclick = (() -> saveImage())
document.getElementById("go").onclick = (() -> go())
