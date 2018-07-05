data = JSON.parse Utils.domLoadDataSync "data/data.json"

# Variables
rows = data.buckets.length
gutter = 10
bucketSize = 86
tagWidthRatio = 0.20
padding = 20
scalefactor = 0.78
borderRadius = 8

screenshot.blur = 6

container = new Layer
	x: Align.center, y: Screen.midY
	width: Screen.width, height: Screen.height/2
	borderRadius: 2*borderRadius
	backgroundColor: "white"
	parent: screen_1
	opacity: 0.89

tittle = new TextLayer
	y: Align.top(padding)
	textAlign: Align.center
	fontWeight: "bold"
	color: "black"
	parent: container

scroll = new ScrollComponent
	x: Align.center
	y: Align.bottom
	width: Screen.width
	height: bucketSize*2
	scrollVertical: false
	backgroundColor: "transparent"
	parent: screen_1
scroll.mouseWheelEnabled = true
scroll.directionLock = false
scroll.content.draggable.bounce = true


class Bucket extends Layer
	constructor: (@options={}) ->
		@options.width = bucketSize
		@options.height = bucketSize
		@options.parent = scroll.content
		@options.borderRadius = borderRadius
		@options.scale = 1
		
		
		@thumbnail = new Layer
			borderRadius:  borderRadius

		super @options
		
		@thumbnail.parent = @
		@thumbnail.width = bucketSize*0.7
		@thumbnail.height = bucketSize*0.7	
		@thumbnail.center()
	
		@onClick ->
			scroll.scrollToPoint(Utils.frameCenterPoint(@.frame))


focusedFrame = new Layer
	backgroundColor: "transparent"
	borderWidth: 6, borderRadius: borderRadius, borderColor: "rgba(255,255,255,0)"
	width: bucketSize*1.4, height: bucketSize*1.4
	shadowBlur: 6, shadowY: 1, shadowColor: "gray"
	x: Align.center, y: Align.center
	parent: scroll

centerFrame = focusedFrame.screenFrame
centerPoint = Utils.frameCenterPoint(centerFrame)

		
scroll.contentInset =
	left: focusedFrame.screenFrame.x + 0.2*bucketSize 
	right:focusedFrame.screenFrame.x + 0.2*bucketSize
buckets = []
middleObjectIndex = Math.round(rows/2) - 1
scaleForIndex = (index) ->
	if index != middleObjectIndex
		return Math.pow scalefactor, Math.abs(middleObjectIndex - index)
	else
		return 1

for bucket, index in data.buckets
		cell = new Bucket
			name: "bucket #{index+1}"
			x: index*(gutter+bucketSize)
			backgroundColor: bucket.backgroundColor, opacity: scaleForIndex(index)
		cell.thumbnail.image = bucket.image
		
		cell.centerY()
		cell.scale = scaleForIndex(index)
		cell.data = bucket
		buckets[index] = cell


tags = [0...10]
tagLayers = []
tagsContainer = new ScrollComponent
	width: Screen.width*0.9, height: container.height - tittle.height - scroll.height
	y: padding + tittle.height, x: Align.center
	parent: container
tagsContainer.scrollHorizontal = false
tagsContainer.content.backgroundColor = "transparent"
tagsContainer.backgroundColor = "transparent"
tagsContainer.mouseWheelEnabled = true
tagsContainer.visible = true
tagsContainer.content.clip = false
tagsContainer.contentInset = 
		left: padding
		top: padding
		bottom: padding	

class Tag extends Layer
	constructor: (@options={}) ->
		@options.height = @options.width*tagWidthRatio
# 		@options.backgroundColor = "#D1D1D1"
		@options.backgroundColor = "transparent"
		@options.borderRadius = borderRadius
		@options.shadowBlur = 6
		@options.shadowY = 1
		@options.shadowColor = "gray"
		autoSize: true
		clip: true
		
		@label = new TextLayer
			width: 0.6*@options.width
			x: Align.left(8), y: Align.center
			fontSize: 14
			name: ".label"
			color: "black"
			clip: true
		
		@trendLabel = new TextLayer
			fontSize: 12
			name: ".trendLabel"
			color: "black"
			clip: true
			
		@trendIcon = new Layer
			width: 1.83*0.3*@options.height, height: 0.3*@options.height
			y: Align.center

			
		super @options
		
		
		@label.parent = @
		@label.centerY()
		@label.backgroundColor = "transparent"
		
		@trendLabel.parent = @
		@trendLabel.centerY()
		@trendLabel.x = @trendIcon.x + 4
		@trendLabel.backgroundColor = "transparent"
		
		@trendIcon.parent = @
		@trendIcon.centerY()
		@trendIcon.x = @label.x + 4
		@trendIcon.image = "images/trend.png"

for tagObject, tagIndex in tags
	tagWidth = (tagsContainer.width-2.2*padding)/2
	tagHeight = tagsContainer.height*0.2
	tagLayer = new Tag
		width: tagWidth
	xPosition = if (tagIndex%2 != 0 and tagIndex !=0) then tagWidth + padding 				else 0
	yPosition = (Math.floor(tagIndex/2)) *(tagHeight)
	tagLayer.parent = tagsContainer.content
	tagLayer.x = xPosition
	tagLayer.y = yPosition
	tagLayer.label.text = ""
	tagLayer.trendLabel.text = ""	
	tagLayer.visible = false
	tagLayers.push(tagLayer)	


scroll.scrollToPoint(centerPoint)

scroll.onMove ->
	if focusedBucket = (bucket for bucket in buckets when Utils.frameInFrame(bucket.screenFrame, focusedFrame.screenFrame))[0]
		tagsContainer.scrollToTop()
		focusedBucketIndex = buckets.indexOf(focusedBucket)
		tittle.text = focusedBucket.data.name
		tittle.centerX()
		
		for tagLay in tagLayers
			tagLay.visible = false 
		
		for tagObject, tagIndex in focusedBucket.data.tags when tagIndex < tags.length
			tagLayer = tagLayers[tagIndex]
			
			tagLayer.label.text = tagObject.name.slice(0, 12);
			tagLayer.trendLabel.x = tagLayer.trendIcon.x + tagLayer.trendIcon.width + 4
			tagLayer.trendIcon.x = tagLayer.label.x + tagLayer.label.width + 4
			roundOff = Math.round(tagObject.noOfShares/10000)
			if roundOff > 100 
				roundOff = Math.round(roundOff/100)
			tagLayer.trendLabel.text = roundOff + "k"
			tagLayer.visible = true	

		for bucket, index in buckets 
			scale = Math.pow scalefactor, Math.abs(focusedBucketIndex - index)
			bucket.scale = if index != focusedBucketIndex then scale else 1				
			bucket.opacity = if index != focusedBucketIndex then scale else 1


scroll.onScrollEnd ->	
# 		scroll.scrollToPoint(centerPoint)
