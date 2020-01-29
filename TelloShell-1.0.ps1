Add-Type -AssemblyName System.speech

$client = new-object net.sockets.udpclient(0)
$client.Client.ReceiveTimeout = 5000
$endpoint = New-Object System.Net.IPEndPoint ([IPAddress]::Any, 8890)

$peerIP = "192.168.10.1"
$peerPort = "8889"

##Setup the speaker, this allows the computer to talk
$speaker = [System.Speech.Synthesis.SpeechSynthesizer]::new();
$speaker.SelectVoice("Microsoft Zira Desktop");

##Setup the Speech Recognition Engine, this allows the computer to listen
$speechRecogEng = [System.Speech.Recognition.SpeechRecognitionEngine]::new();

## Setup Keywords for voice commands
$keywords = @(
    "hello",
    "exit",
    "connect",
    "launch",
    "land",
    "flip",
    "battery",
    "speed",
    "time",
    "wifi",
    "sdk",
    "serial number",
    "video stream on",
    "video stream off"
)
    
## Load keywords into grammerBuilder
write-host "Loading commands..." -foreground "white"
$ii=0;
foreach($key in $keywords) {
  $i = [System.Speech.Recognition.GrammarBuilder]::new();
  $i.Append($key);
  $speechRecogEng.LoadGrammar($i);
  $i = $ii + 1
}

## Setup Listener
$speechRecogEng.InitialSilenceTimeout = 0 # Time delay for listening
$speechRecogEng.SetInputToDefaultAudioDevice();
$cmdBoolean = $false;

write-host "Enabling listen mode..." -foreground "yellow"
$speaker.Speak("Starting Tello Shell version 1.0, ready for command")

## Do something with the command found
while (!$cmdBoolean) {
  $speechRecognize = $speechRecogEng.Recognize();
  $conf = $speechRecognize.Confidence;
  $myWords = $speechRecognize.text;
  if ($myWords -match "hello" -and [double]$conf -gt 0.80) {
    $speaker.Speak("Hello")
  }
  if ($myWords -match "exit" -and [double]$conf -gt 0.80) {
    $speaker.Speak("Goodbye")
    $cmdBoolean = $true;
  }
  if ($myWords -match "connect" -and [double]$conf -gt 0.80) {
    $speaker.Speak("Connecting to Tello")
    $send = [text.encoding]::ascii.getbytes("command")
    [void] $client.send($send, $send.length, $peerIP, $peerPort)

    $content = $client.Receive([ref]$endpoint)
    [Text.Encoding]::ASCII.GetString($content)
  }
  if ($myWords -match "launch" -and [double]$conf -gt 0.80) {
    $speaker.Speak("Launching")
    $send = [text.encoding]::ascii.getbytes("takeoff")
    [void] $client.send($send, $send.length, $peerIP, $peerPort)
  }
  if ($myWords -match "land" -and [double]$conf -gt 0.80) {
    $speaker.Speak("Landing")
    $send = [text.encoding]::ascii.getbytes("land")
    [void] $client.send($send, $send.length, $peerIP, $peerPort)
  }
  if ($myWords -match "flip" -and [double]$conf -gt 0.80) {
    $speaker.Speak("Flipping")
    $send = [text.encoding]::ascii.getbytes("flip l")
    [void] $client.send($send, $send.length, $peerIP, $peerPort)
  }
  if ($myWords -match "battery" -and [double]$conf -gt 0.80) {
    $send = [text.encoding]::ascii.getbytes("battery?")
    [void] $client.send($send, $send.length, $peerIP, $peerPort)

    $content = $client.Receive([ref]$endpoint)
    $response = [Text.Encoding]::ASCII.GetString($content)
    $speaker.Speak("Battery level is $response-percent full.")
  }
  if ($myWords -match "speed" -and [double]$conf -gt 0.80) {
    $send = [text.encoding]::ascii.getbytes("speed?")
    [void] $client.send($send, $send.length, $peerIP, $peerPort)

    $content = $client.Receive([ref]$endpoint)
    $response = [Text.Encoding]::ASCII.GetString($content)
    $speaker.Speak("Current speed is $response centimeters per second")
  }
  if ($myWords -match "time" -and [double]$conf -gt 0.80) {
    $send = [text.encoding]::ascii.getbytes("time?")
    [void] $client.send($send, $send.length, $peerIP, $peerPort)

    $content = $client.Receive([ref]$endpoint)
    $response = [Text.Encoding]::ASCII.GetString($content)
    $speaker.Speak("Current flight time is $response seconds")
  }
  if ($myWords -match "wifi" -and [double]$conf -gt 0.80) {
    $send = [text.encoding]::ascii.getbytes("wifi?")
    [void] $client.send($send, $send.length, $peerIP, $peerPort)

    $content = $client.Receive([ref]$endpoint)
    $response = [Text.Encoding]::ASCII.GetString($content)
    $speaker.Speak("Wi-Fi SNR is $response")
  }
  if ($myWords -match "sdk" -and [double]$conf -gt 0.80) {
    $send = [text.encoding]::ascii.getbytes("sdk?")
    [void] $client.send($send, $send.length, $peerIP, $peerPort)

    $content = $client.Receive([ref]$endpoint)
    $response = [Text.Encoding]::ASCII.GetString($content)
    $speaker.Speak("Tello SDK version is $response")
  }
  if ($myWords -match "serial number" -and [double]$conf -gt 0.80) {
    $send = [text.encoding]::ascii.getbytes("sn?")
    [void] $client.send($send, $send.length, $peerIP, $peerPort)

    $content = $client.Receive([ref]$endpoint)
    $response = [Text.Encoding]::ASCII.GetString($content)
    $speaker.Speak("Tello SDK serial number is $response")
  }
  if ($myWords -match "video stream on" -and [double]$conf -gt 0.80) {
    $speaker.Speak("Starting Video Stream")
    $send = [text.encoding]::ascii.getbytes("streamon")
    [void] $client.send($send, $send.length, $peerIP, $peerPort)
    Start-Process 'C:\Program Files\VideoLAN\VLC\vlc.exe' -ArgumentList "udp://192.168.10.1:11111"
  }
}