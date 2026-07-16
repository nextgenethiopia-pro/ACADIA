import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'

const TELEGRAM_BOT_TOKEN = Deno.env.get('TELEGRAM_BOT_TOKEN') ?? ''
const TELEGRAM_CHAT_ID = Deno.env.get('TELEGRAM_CHAT_ID') ?? ''

serve(async (req) => {
  try {
    if (!TELEGRAM_BOT_TOKEN || !TELEGRAM_CHAT_ID) {
      throw new Error('Telegram credentials are not configured (set TELEGRAM_BOT_TOKEN and TELEGRAM_CHAT_ID)')
    }

    const { record } = await req.json()
    
    // Get Supabase client
    const supabaseUrl = Deno.env.get('SUPABASE_URL')
    const supabaseKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')
    
    // Fetch user details
    const userResponse = await fetch(
      `${supabaseUrl}/rest/v1/profiles?id=eq.${record.user_id}&select=*`,
      {
        headers: {
          'Authorization': `Bearer ${supabaseKey}`,
          'apikey': supabaseKey,
        },
      }
    )
    
    const users = await userResponse.json()
    const user = users[0]
    
    if (!user) {
      throw new Error('User not found')
    }
    
    // Format the message
    const message = `
🎓 <b>New Payment Submission</b>

👤 <b>Student Information:</b>
• Name: ${user.full_name}
• Email: ${user.email}
• Phone: ${user.phone_number}
• Academic Path: ${user.academic_level}${user.grade ? ' - Grade ' + user.grade : ''}${user.stream ? ' (' + user.stream + ')' : ''}

💰 <b>Payment Details:</b>
• Package: ${record.package_name}
• Amount: ${record.amount} ETB
• Method: ${record.method.toUpperCase()}
• Account Number: ${record.user_account_number}
• Transaction Ref: ${record.transaction_reference}

📅 Submitted: ${new Date(record.created_at).toLocaleString()}

<a href="${supabaseUrl}/storage/v1/object/public/receipts/${record.receipt_image_url}">📄 View Receipt</a>
    `.trim()
    
    // Send Telegram message
    const telegramResponse = await fetch(
      `https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage`,
      {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          chat_id: TELEGRAM_CHAT_ID,
          text: message,
          parse_mode: 'HTML',
        }),
      }
    )
    
    if (!telegramResponse.ok) {
      const error = await telegramResponse.text()
      throw new Error(`Telegram API error: ${error}`)
    }
    
    return new Response(
      JSON.stringify({ success: true }),
      { headers: { 'Content-Type': 'application/json' } }
    )
  } catch (error) {
    console.error('Error:', error)
    return new Response(
      JSON.stringify({ success: false, error: error.message }),
      { 
        status: 500,
        headers: { 'Content-Type': 'application/json' }
      }
    )
  }
})
