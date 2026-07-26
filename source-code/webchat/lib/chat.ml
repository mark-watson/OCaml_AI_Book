(* Pure parts of the chat server: the Gemini request/response codec and the
   single-page HTML. Keeping these out of the Dream handler lets the tests run
   without a server or an API key. *)

let gemini_request prompt =
  `Assoc
    [ ( "contents",
        `List
          [ `Assoc [ ("parts", `List [ `Assoc [ ("text", `String prompt) ] ]) ] ] );
      ( "generationConfig",
        `Assoc
          [ ("temperature", `Float 0.1); ("maxOutputTokens", `Int 800) ] )
    ]

let text_of_json json =
  let open Yojson.Safe.Util in
  match json |> member "candidates" |> to_list with
  | candidate :: _ -> (
    match candidate |> member "content" |> member "parts" |> to_list with
    | part :: _ -> Ok (part |> member "text" |> to_string)
    | [] -> Error "No content in response")
  | [] -> Error "No candidates in response"
  | exception _ -> Error "Failed to parse Gemini response"

(* Read the "prompt" field from the browser's POST body. *)
let prompt_of_body body =
  try
    Yojson.Safe.from_string body |> Yojson.Safe.Util.member "prompt"
    |> Yojson.Safe.Util.to_string
  with _ -> ""

let page =
  {page|<!DOCTYPE html>
<html>
<head><title>Gemini Chat</title></head>
<body>
  <h1>Gemini Chat</h1>
  <form id='chat-form'>
    <input type='text' id='prompt' name='prompt' placeholder='Enter your prompt'
           style='width: 70%; padding: 10px; font-size: 16px;'>
    <button type='submit'>Send</button>
  </form><br/><br/><h4>Response:</h4>
  <div id='response'></div>
  <script>
   const form = document.getElementById('chat-form');
   const responseDiv = document.getElementById('response');
   form.addEventListener('submit', async (event) => {
     event.preventDefault();
     const prompt = document.getElementById('prompt').value;
     try {
       const response = await fetch('/chat', {
         method: 'POST',
         headers: { 'Content-Type': 'application/json' },
         body: JSON.stringify({ prompt: prompt })
       });
       const data = await response.json();
       responseDiv.innerText = data.text;
     } catch (error) {
       console.error('Error:', error);
       responseDiv.innerText = 'Error occurred while fetching response';
     }
   });
  </script>
</body>
</html>|page}
