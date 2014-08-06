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
    for i in [1..numGenes] by 1
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
    @iteration = 0

  run: () ->
    @updateDisplays()
    @recomputeScores()

    @bestScoreField.innerText = @findBestScore()
    @iterationField.innerText = @iteration

    @killWorst()
    @killWorst()

    @breedRandomTwo()

    @mutateOne()
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
    start = 0
    @ybar = Binary.toInt binary[start..start+varBitCount]
    start += varBitCount
    @xbar = Binary.toInt binary[start..start+varBitCount]
    start += varBitCount
    @y = Binary.toInt binary[start..start+varBitCount]
    start += varBitCount
    @x = Binary.toInt binary[start..start+varBitCount]
    start += varBitCount

    @r = Binary.toInt binary[start..start+varBitCount]
    start += varBitCount
    @g = Binary.toInt binary[start..start+varBitCount]
    start += varBitCount
    @b = Binary.toInt binary[start..start+varBitCount]
    start += varBitCount
    a = Binary.toInt binary[start..start+varBitCount]
    @a = a / 255
    start += varBitCount

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

  constructor: (@binary, @g) ->
    binary = @binary
    @rectangles = []

    start = 0
    b = Rectangle.bitCount

    until start is binary.length
      rectangleBinary = binary[start..start+Rectangle.bitCount]
      start += Rectangle.bitCount
      @rectangles.push new Rectangle rectangleBinary
    
  getGraphics: () -> @g

  getBinary: () -> @binary

  drawSelf: () ->
    @g.clearRect 0, 0, size, size
    rectangle.drawSelf @g for rectangle in @rectangles

  printSelf: () ->
    for rectangle, i in @rectangles
      console.log "rectangle #{i}"
      rectangle.printSelf()

class Scorer
  constructor: (base) ->
    @standardColors = (base.getImageData 0, 0, ImageMatcher.size, ImageMatcher.size).data

  score: (graphics) ->
    imageColors = (graphics.getImageData 0, 0, ImageMatcher.size, ImageMatcher.size).data
    score = 0
    score += Math.abs(imageColors[i] - @standardColors[i]) for i in [0...imageColors.length] by 1 when i % 4 isnt 3
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
  @normalize: (b1, b2) ->
    if b1.length > b2.length
      b2 = (0 for i in [b2.length...b1.length] by 1).concat b2
    else if b2.length > b1.length
      b1 = (0 for i in [b1.length...b2.length] by 1).concat b1
    [b1, b2]
  @and: (b1, b2) ->
    [b1, b2] = @normalize b1, b2
    (b1[i] and b2[i] for i in [0...b1.length] by 1)
  @or: (b1, b2) ->
    [b1, b2] = @normalize b1, b2
    (b1[i] or b2[i] for i in [0...b1.length] by 1)
  @toInt: (b) ->
    parseInt(b.join(""), 2)
  @random: (numbits) ->
    ((if Math.random() < .5 then 1 else 0) for i in [1..numbits] by 1)

imageMatcher = null
go = () ->
  numRectangles = document.getElementById("numrectangles").value
  numGenes = document.getElementById("numgenes").value
  imageURL = document.getElementById("imageurl").value
  imageMatcher = new ImageMatcher imageURL, numRectangles, numGenes
  document.getElementById("instantiation").hidden = "true"
  setTimeout start, 1000

start = () -> setInterval (() -> imageMatcher.run()), 0

saveImage = () ->
  index = imageMatcher.getBestRectangleCollectionIndex() + 1
  dataURL = document.getElementById("canvas#{index}").toDataURL()
  document.getElementById("snapshot").src = dataURL

document.getElementById("save").onclick = saveImage
document.getElementById("go").onclick = go
