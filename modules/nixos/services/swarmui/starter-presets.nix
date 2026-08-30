{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.khanelinix.services.swarmui;
  comfyuiCfg = config.khanelinix.services.comfyui;
  comfyuiModels = comfyuiCfg.models;

  hasModel = builtins.hasAttr;
  clipSegDirectory = "clipseg/clipseg-rd64-refined-fp16-safetensors";
  clipSegFiles = map (file: "${clipSegDirectory}/${file}") [
    "config.json"
    "merges.txt"
    "model.safetensors"
    "preprocessor_config.json"
    "special_tokens_map.json"
    "tokenizer_config.json"
    "vocab.json"
  ];
  hasClipSegBundle = lib.all (name: hasModel name comfyuiModels) clipSegFiles;
  promptGuide =
    "Write an adult subject first. Then add appearance, pose or action, expression, "
    + "clothing, setting, lighting, composition, lens, and finish.";

  starterPresets =
    lib.optionals (hasModel "checkpoints/CyberRealisticXLPlay_V10.0_FP16.safetensors" comfyuiModels) [
      {
        id = "cyberrealistic-xl-photo-v1";
        title = "Khanelinix - CyberRealistic XL Photo";
        description = "${promptGuide} This preset appends CyberRealistic photo and artifact terms.";
        paramMap = {
          model = "CyberRealisticXLPlay_V10.0_FP16";
          prompt =
            "{value}, RAW photo, natural skin texture, realistic anatomy, "
            + "physically plausible lighting, sharp focus";
          negativeprompt = "{value}, lowres, bad anatomy, bad hands, watermark";
          steps = "30";
          cfgscale = "4.5";
          sampler = "dpmpp_2m_sde";
          scheduler = "karras";
          automaticvae = "false";
          vae = "None";
        };
      }
    ]
    ++
      lib.optionals
        (
          hasModel "checkpoints/Realistic_Vision_V6.0_NV_B1_fp16.safetensors" comfyuiModels
          && hasModel "vae/vae-ft-mse-840000-ema-pruned.safetensors" comfyuiModels
        )
        [
          {
            id = "realistic-vision-photo-v1";
            title = "Khanelinix - Realistic Vision Photo";
            description = "${promptGuide} This preset appends the model-card photo and negative terms.";
            paramMap = {
              model = "Realistic_Vision_V6.0_NV_B1_fp16";
              prompt = "{value}, RAW photo, 8k uhd, dslr, soft lighting, high quality, film grain, Fujifilm XT3";
              negativeprompt =
                "{value}, deformed iris, deformed pupils, semi-realistic, cgi, 3d, render, "
                + "sketch, cartoon, drawing, anime, text, cropped, out of frame, worst quality, "
                + "low quality, jpeg artifacts, ugly, duplicate, morbid, mutilated, extra fingers, "
                + "mutated hands, poorly drawn hands, poorly drawn face, mutation, deformed, blurry, "
                + "dehydrated, bad anatomy, bad proportions, extra limbs, cloned face, disfigured, "
                + "gross proportions, malformed limbs, missing arms, missing legs, extra arms, "
                + "extra legs, fused fingers, too many fingers, long neck";
              steps = "30";
              cfgscale = "5";
              sampler = "dpmpp_sde";
              scheduler = "karras";
              automaticvae = "false";
              vae = "vae-ft-mse-840000-ema-pruned";
            };
          }
        ]
    ++ lib.optionals hasClipSegBundle [
      {
        id = "clipseg-face-refine-v1";
        title = "Khanelinix - CLIPSeg Face Refine";
        description =
          "Append one face refinement at creativity 0.6 and threshold 0.5. "
          + "Compare the same seed because refinement can change identity or add seams.";
        paramMap.prompt = "{value} <segment:face,0.6,0.5>";
      }
    ];

  presetManifest = pkgs.writeText "swarmui-starter-presets.json" (builtins.toJSON starterPresets);

  apiHost =
    if cfg.host == "0.0.0.0" then
      "127.0.0.1"
    else if cfg.host == "::" then
      "::1"
    else
      cfg.host;
  apiAuthority = if lib.hasInfix ":" apiHost then "[${apiHost}]" else apiHost;
  apiUrl = "http://${apiAuthority}:${toString cfg.port}";

  presetSeeder = pkgs.writeShellApplication {
    name = "swarmui-seed-starter-presets";
    runtimeInputs = [
      pkgs.coreutils
      pkgs.curl
      pkgs.jq
    ];
    text = ''
      stateDir="''${STATE_DIRECTORY:?systemd did not provide STATE_DIRECTORY}"
      apiUrl=${lib.escapeShellArg apiUrl}

      postApi() {
        local endpoint=$1
        local payload=$2

        curl \
          --fail \
          --silent \
          --show-error \
          --max-time 5 \
          --header 'Content-Type: application/json' \
          --data "$payload" \
          "$apiUrl/API/$endpoint"
      }

      sessionId=
      for attempt in {1..60}; do
        if sessionResponse=$(postApi GetNewSession '{}') \
          && sessionId=$(jq -er '.session_id | strings | select(length > 0)' <<<"$sessionResponse" 2>/dev/null); then
          break
        fi

        if (( attempt == 60 )); then
          echo "SwarmUI API did not become ready at $apiUrl" >&2
          exit 1
        fi

        sleep 1
      done

      sessionPayload=$(jq -nc --arg sessionId "$sessionId" '{session_id: $sessionId}')
      userData=$(postApi GetMyUserData "$sessionPayload")
      jq -e '.presets | arrays' <<<"$userData" >/dev/null

      while IFS= read -r preset; do
        presetId=$(jq -er '.id' <<<"$preset")
        title=$(jq -er '.title' <<<"$preset")
        marker="$stateDir/$presetId"

        if [[ -e "$marker" ]]; then
          continue
        fi

        if ! jq -e --arg title "$title" '.presets | any(.title == $title)' <<<"$userData" >/dev/null; then
          request=$(jq -nc \
            --arg sessionId "$sessionId" \
            --argjson preset "$preset" \
            '{
              session_id: $sessionId,
              title: $preset.title,
              description: $preset.description,
              param_map: $preset.paramMap,
              is_edit: false,
              is_starred: false
            }')
          response=$(postApi AddNewPreset "$request")

          if ! jq -e \
            '.success == true or .preset_fail == "A preset with that title already exists."' \
            <<<"$response" >/dev/null; then
            echo "SwarmUI rejected starter preset '$title': $(jq -c . <<<"$response")" >&2
            exit 1
          fi

          userData=$(postApi GetMyUserData "$sessionPayload")
        fi

        if ! jq -e --arg title "$title" '.presets | any(.title == $title)' <<<"$userData" >/dev/null; then
          echo "SwarmUI did not return starter preset '$title' after creation" >&2
          exit 1
        fi

        printf '%s\n' "$title" >"$marker.tmp"
        mv "$marker.tmp" "$marker"
      done < <(jq -c '.[]' ${presetManifest})
    '';
  };
in
{
  config = lib.mkIf (cfg.enable && comfyuiCfg.enable && starterPresets != [ ]) {
    systemd.services.swarmui-starter-presets = {
      description = "Seed user-owned SwarmUI starter presets";
      wantedBy = [ "multi-user.target" ];
      requires = [ "swarmui.service" ];
      after = [ "swarmui.service" ];

      serviceConfig = {
        Type = "oneshot";
        ExecStart = lib.getExe presetSeeder;
        RemainAfterExit = true;

        DynamicUser = true;
        StateDirectory = "swarmui-starter-presets";
        StateDirectoryMode = "0700";
        UMask = "0077";

        Restart = "on-failure";
        RestartSec = "30s";
        TimeoutStartSec = "2min";

        ProtectSystem = "strict";
        ProtectHome = true;
        PrivateTmp = true;
        NoNewPrivileges = true;
      };
    };
  };
}
