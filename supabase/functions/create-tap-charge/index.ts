import "jsr:@supabase/functions-js/edge-runtime.d.ts";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type, x-sana-guest-id",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

function jsonResponse(
  body: Record<string, unknown>,
  status = 200,
): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: {
      ...corsHeaders,
      "Content-Type": "application/json",
    },
  });
}

Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", {
      headers: corsHeaders,
    });
  }

  if (req.method !== "POST") {
    return jsonResponse({ error: "Method not allowed" }, 405);
  }

  try {
    const tapSecretKey = Deno.env.get("TAP_SECRET_KEY");

    if (!tapSecretKey || tapSecretKey.trim().length === 0) {
      return jsonResponse(
        { error: "TAP_SECRET_KEY is not configured in Supabase Secrets" },
        500,
      );
    }

    let requestBody: Record<string, unknown> = {};
    const bodyText = await req.text();

    if (bodyText.trim().length > 0) {
      try {
        const parsed = JSON.parse(bodyText);

        if (
          parsed !== null &&
          typeof parsed === "object" &&
          !Array.isArray(parsed)
        ) {
          requestBody = parsed as Record<string, unknown>;
        }
      } catch (_) {
        return jsonResponse(
          { error: "Invalid JSON request body" },
          400,
        );
      }
    }

    const firstName =
      typeof requestBody["first_name"] === "string" &&
      requestBody["first_name"].trim().length > 0
        ? requestBody["first_name"].trim()
        : "Customer";

    const lastName =
      typeof requestBody["last_name"] === "string"
        ? requestBody["last_name"].trim()
        : "";

    const email =
      typeof requestBody["email"] === "string"
        ? requestBody["email"].trim()
        : "";

    const countryCode =
      typeof requestBody["country_code"] === "string"
        ? requestBody["country_code"].trim()
        : "";

    const phoneNumber =
      typeof requestBody["phone_number"] === "string"
        ? requestBody["phone_number"].trim()
        : "";

    const customer: Record<string, unknown> = {
      first_name: firstName,
    };

    if (lastName.length > 0) {
      customer["last_name"] = lastName;
    }

    if (email.length > 0) {
      customer["email"] = email;
    }

    if (countryCode.length > 0 && phoneNumber.length > 0) {
      customer["phone"] = {
        country_code: countryCode,
        number: phoneNumber,
      };
    }

    const tapPayload: Record<string, unknown> = {
      amount: 50,
      currency: "USD",
      customer_initiated: true,
      threeDSecure: true,
      save_card: false,
      description: "Get your own copy payment",
      customer,
      source: { id: "src_all" },
      redirect: {
        url: "https://example.com",
      },
    };

    const tapResponse = await fetch(
      "https://api.tap.company/v2/charges/",
      {
        method: "POST",
        headers: {
          Authorization: `Bearer ${tapSecretKey}`,
          "Content-Type": "application/json",
          Accept: "application/json",
          lang_code: "en",
        },
        body: JSON.stringify(tapPayload),
      },
    );

    const responseText = await tapResponse.text();

    let tapData: unknown;

    try {
      tapData = JSON.parse(responseText);
    } catch (_) {
      tapData = {
        raw_response: responseText,
      };
    }

    if (!tapResponse.ok) {
      return jsonResponse(
        {
          error: "Tap payment creation failed",
          tap_status: tapResponse.status,
          tap_response: tapData,
        },
        tapResponse.status,
      );
    }

    return new Response(
      JSON.stringify(tapData),
      {
        status: 200,
        headers: {
          ...corsHeaders,
          "Content-Type": "application/json",
        },
      },
    );
  } catch (error) {
    return jsonResponse(
      {
        error:
          error instanceof Error
            ? error.message
            : String(error),
      },
      500,
    );
  }
});