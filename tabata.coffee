exercises = ["Running in Place", "Jumping Jacks", "Jumping Squats", "Push Ups", "Bicycle Crunch", "Burpees", "Mason Twist", "Mountain Climbers"]

timer = document.getElementById("timer")
exercise = document.getElementById("exercise")
image = document.getElementById("img")

clong = new Audio("clong.mp3")

countdowner = (time, nextFunction) ->
  setTimerText time
  if time is 0
    clong.play()
    nextFunction()
  else
    setTimeout (() -> countdowner time - 1, nextFunction), 1000

start = () ->
  setExerciseText "Get Ready!"
  countdowner 3, (() -> showExercise 0)

showExercise = (index) ->
  setExerciseText exercises[index]
  setImage "img/" + exercises[index] + ".png"
  countdowner 20, (() -> showResting index)

showResting = (index) ->
  setImage ""
  if isLastIndex index
    end()
  else
    setExerciseText "Resting (#{ exercises[index + 1]} Next)"
    countdowner 10, (() -> showExercise index + 1)

end = () ->
  setTimerText ""
  setExerciseText "All Done!"

setTimerText = (text) -> timer.innerText = text
setExerciseText = (text) -> exercise.innerText = text
setImage = (img) -> image.src = img
isLastIndex = (index) -> exercises[index + 1] is undefined
