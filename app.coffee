data = JSON.parse Utils.domLoadDataSync "data/data.json"

# Variables
rows = data.buckets.length
gutter = 20
bucketSize = 56
tagWidthRatio = 0.20
padding = 20
scalefactor = 1
borderRadius = 8

screenshot.blur = 6

container = new Layer
	x: Align.center, y: Screen.midY
	width: Screen.width, height: Screen.height/2
	borderRadius: 2*borderRadius
	backgroundColor: "white"
	parent: screen_1
# 	opacity: 0.89


focusedFrame = new PageComponent
	backgroundColor: "transparent"
	borderWidth: 6, borderRadius: borderRadius, borderColor: "rgba(255,255,255,0)"
	width: bucketSize*1.4, height: bucketSize*1.4
	shadowBlur: 6, shadowY: 1, shadowColor: "gray"
	x: Align.center, y: Align.bottom(-padding)
	parent: container
	clip: false
	z: 1
	scrollVertical: false

centerFrame = focusedFrame.screenFrame
centerPoint = Utils.frameCenterPoint(centerFrame)

class Bucket extends Layer
	constructor: (@options={}) ->
		@options.width = bucketSize
		@options.height = bucketSize
		@options.parent = focusedFrame.content
		@options.borderRadius = borderRadius
		@options.scale = 1
		
		
		@thumbnail = new Layer
			borderRadius:  borderRadius

		super @options
		
		@thumbnail.parent = @
		@thumbnail.width = bucketSize*0.7
		@thumbnail.height = bucketSize*0.7	
		@thumbnail.center()
		@thumbnail.style = backgroundSize: "contain"
		
		@onClick ->
			focusedFrame.snapToPage(@)
			@.states.switchInstant "active"
			
		@states=
			"active":
				opacity: 1
				scale: 1
			"default":
				opacity: 0.6
				scale: 0.98
			

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
			x: index*(gutter+bucketSize) + padding
			backgroundColor: bucket.backgroundColor, opacity: scaleForIndex(index)
		cell.thumbnail.image = bucket.image
	
		cell.centerY()
		cell.scale = scaleForIndex(index)
		cell.data = bucket
		buckets[index] = cell


tags = [0...10]
tagLayers = []
tagsContainer = new ScrollComponent
	width: Screen.width*0.9, height: container.height
	y: 0, x: Align.center
	parent: container

tagsContainer.scrollHorizontal = false
tagsContainer.content.backgroundColor = "transparent"
tagsContainer.backgroundColor = "transparent"
tagsContainer.mouseWheelEnabled = true
tagsContainer.visible = true
tagsContainer.content.clip = false
tagsContainer.contentInset = 
		top: padding
		bottom: padding	

tittle = new TextLayer
	y: Align.top
	textAlign: Align.center
	fontWeight: "bold"
	fontSize: 20
	color: "black"
	parent: tagsContainer.content

blurLayer = new Layer
	parent: container
	y: Align.bottom(-padding)
	height: bucketSize*1.4
	width: Screen.width
	backgroundColor: "white"
	blur: 30
	opacity: 0.9
		
class Tag extends Layer
	constructor: (@options={}) ->
		@options.height = @options.width*tagWidthRatio
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
			fontSize: 16
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
		@trendLabel.x = @trendIcon.x +  @trendIcon.width + 4
		@trendLabel.backgroundColor = "transparent"
		
		@trendIcon.parent = @
		@trendIcon.centerY()
		@trendIcon.x = @label.x + @label.width + 4
		@trendIcon.image = "images/trend.png"
		
yPosition = tittle.height + tittle.y

for tagObject, tagIndex in tags
	tagWidth = (tagsContainer.width-1.2*padding)/2
	tagHeight = 48
	tagLayer = new Tag
		width: tagWidth
	xPosition = if (tagIndex%2 != 0 and tagIndex !=0) then tagWidth + padding 				else 0.2*padding
	yPosition = tittle.height + tittle.y + padding + (Math.floor(tagIndex/2)) *(tagHeight)
	tagLayer.parent = tagsContainer.content
	tagLayer.x = xPosition
	tagLayer.y = yPosition
	tagLayer.label.text = ""
	tagLayer.trendLabel.text = ""	
	tagLayer.visible = false
	tagLayers.push(tagLayer)	

focusedFrame.on "change:currentPage", ->
	
		current = focusedFrame.verticalPageIndex(focusedFrame.currentPage)
		focusedBucket = buckets[current]
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
			if index != current
				bucket.states.switchInstant "default"
			else 
				bucket.states.switchInstant "active"

focusedFrame.snapToPage(focusedFrame.content.children[4])
